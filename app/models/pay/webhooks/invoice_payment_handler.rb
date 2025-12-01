# frozen_string_literal: true

module Pay
  module Webhooks
    # Handles Stripe webhook events for invoice payments made via Checkout Sessions
    #
    # Supported events:
    # - checkout.session.completed - Customer completed payment via Stripe Checkout
    # - payment_intent.succeeded - Direct payment intent succeeded (fallback)
    #
    # This handler is registered in config/initializers/pay.rb and processes
    # payments made through the public invoice payment page.
    #
    class InvoicePaymentHandler
      def call(event)
        object = event.data.object
        return unless object

        Rails.logger.info "[InvoicePayment] Processing #{event.type} for #{object.try(:id)}"

        case event.type
        when "checkout.session.completed"
          handle_checkout_session_completed(object)
        when "payment_intent.succeeded"
          handle_payment_intent_succeeded(object)
        end
      rescue StandardError => e
        Rails.logger.error "[InvoicePayment] Error processing #{event.type}: #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        raise # Re-raise to let Pay gem handle retry logic
      end

      private

      def handle_checkout_session_completed(checkout_session)
        invoice_id = checkout_session.metadata&.dig("invoice_id")

        unless invoice_id.present?
          Rails.logger.warn "[InvoicePayment] No invoice_id in checkout session metadata for #{checkout_session.id}"
          return
        end

        # Only process if payment was successful
        unless checkout_session.payment_status == "paid"
          Rails.logger.info "[InvoicePayment] Checkout session #{checkout_session.id} payment_status: #{checkout_session.payment_status}"
          return
        end

        invoice = Invoice.find_by(id: invoice_id)

        unless invoice
          Rails.logger.error "[InvoicePayment] Invoice not found for checkout session #{checkout_session.id}, invoice_id: #{invoice_id}"
          return
        end

        mark_invoice_paid(invoice, checkout_session.payment_intent)
      end

      def handle_payment_intent_succeeded(payment_intent)
        invoice_id = payment_intent.metadata&.dig("invoice_id")

        unless invoice_id.present?
          # This might be a subscription payment or other payment, not an invoice payment
          return
        end

        invoice = Invoice.find_by(id: invoice_id)

        unless invoice
          Rails.logger.error "[InvoicePayment] Invoice not found for payment_intent #{payment_intent.id}, invoice_id: #{invoice_id}"
          return
        end

        mark_invoice_paid(invoice, payment_intent.id)
      end

      def mark_invoice_paid(invoice, payment_reference)
        # Don't update if already paid
        if invoice.paid?
          Rails.logger.warn "[InvoicePayment] Invoice #{invoice.id} is already paid, skipping"
          return
        end

        invoice.mark_as_paid!(
          payment_date: Time.current,
          payment_method: "stripe",
          payment_reference: payment_reference
        )

        Rails.logger.info "[InvoicePayment] Invoice #{invoice.id} marked as paid via Stripe (ref: #{payment_reference})"

        # Optionally send payment confirmation notification
        send_payment_confirmation(invoice)
      end

      def send_payment_confirmation(invoice)
        # TODO: Implement payment confirmation notification
        # InvoicePaymentConfirmationJob.perform_later(invoice.id)
      end
    end
  end
end
