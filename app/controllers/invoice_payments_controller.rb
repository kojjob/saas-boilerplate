# frozen_string_literal: true

# Public controller for invoice payments - no authentication required
# Allows clients to view and pay invoices via Stripe Checkout
class InvoicePaymentsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_tenant_from_subdomain, raise: false
  skip_before_action :set_current_tenant_from_session, raise: false

  before_action :set_invoice

  def show
    # Public payment page showing invoice details
  end

  def checkout
    unless @invoice.payable?
      redirect_to pay_invoice_path(payment_token: @invoice.payment_token),
                  alert: "This invoice has already been paid or is not available for payment."
      return
    end

    unless stripe_configured?
      redirect_to pay_invoice_path(payment_token: @invoice.payment_token),
                  alert: "Payment processing is not configured. Please contact the business directly."
      return
    end

    session = create_stripe_checkout_session
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error for invoice #{@invoice.id}: #{e.message}"
    redirect_to pay_invoice_path(payment_token: @invoice.payment_token),
                alert: "Unable to process payment. Please try again or contact the business."
  end

  def success
    # Payment success page - actual payment confirmation happens via webhook
    @invoice.update(status: :viewed) if @invoice.sent?
  end

  def cancel
    # Payment cancelled page
  end

  private

  def set_invoice
    @invoice = Invoice.find_by_payment_token!(params[:payment_token])
  rescue ActiveRecord::RecordNotFound
    render plain: "Invoice not found", status: :not_found
  end

  def stripe_configured?
    Rails.application.credentials.dig(:stripe, :secret_key).present? ||
      ENV["STRIPE_SECRET_KEY"].present?
  end

  def create_stripe_checkout_session
    Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [ {
        price_data: {
          currency: "usd",
          product_data: {
            name: "Invoice #{@invoice.invoice_number}",
            description: invoice_description
          },
          unit_amount: (@invoice.total_amount * 100).to_i
        },
        quantity: 1
      } ],
      mode: "payment",
      success_url: pay_invoice_success_url(payment_token: @invoice.payment_token),
      cancel_url: pay_invoice_cancel_url(payment_token: @invoice.payment_token),
      metadata: {
        invoice_id: @invoice.id,
        invoice_number: @invoice.invoice_number,
        account_id: @invoice.account_id
      },
      customer_email: @invoice.client.email
    )
  end

  def invoice_description
    items = @invoice.line_items.map(&:description).compact.first(3)
    if items.any?
      items.join(", ").truncate(200)
    else
      "Payment for services"
    end
  end
end
