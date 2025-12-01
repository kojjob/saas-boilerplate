# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pay::Webhooks::InvoicePaymentHandler do
  let(:handler) { described_class.new }
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }
  let(:invoice) { create(:invoice, account: account, client: client, status: :sent) }

  describe "#call" do
    context "with checkout.session.completed event" do
      let(:checkout_session) do
        double(
          "Stripe::Checkout::Session",
          id: "cs_test_123",
          payment_intent: "pi_test_456",
          payment_status: "paid",
          amount_total: 10000, # $100.00 in cents
          currency: "usd",
          metadata: {
            "invoice_id" => invoice.id.to_s,
            "invoice_number" => invoice.invoice_number,
            "account_id" => account.id.to_s
          }
        )
      end

      let(:event) do
        double(
          "Stripe::Event",
          type: "checkout.session.completed",
          data: double("data", object: checkout_session)
        )
      end

      it "marks the invoice as paid" do
        expect { handler.call(event) }.to change { invoice.reload.status }.from("sent").to("paid")
      end

      it "sets the payment_method to 'stripe'" do
        handler.call(event)
        expect(invoice.reload.payment_method).to eq("stripe")
      end

      it "sets the payment_reference to the payment_intent id" do
        handler.call(event)
        expect(invoice.reload.payment_reference).to eq("pi_test_456")
      end

      it "sets the paid_at timestamp" do
        freeze_time do
          handler.call(event)
          expect(invoice.reload.paid_at).to be_within(1.second).of(Time.current)
        end
      end

      it "logs the successful payment" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Invoice #{invoice.id} marked as paid/)
        handler.call(event)
      end

      context "when invoice is already paid" do
        before { invoice.update!(status: :paid) }

        it "does not update the invoice" do
          expect { handler.call(event) }.not_to change { invoice.reload.updated_at }
        end

        it "logs a warning" do
          expect(Rails.logger).to receive(:warn).with(/Invoice #{invoice.id} is already paid/)
          handler.call(event)
        end
      end

      context "when invoice is not found" do
        let(:checkout_session) do
          double(
            "Stripe::Checkout::Session",
            id: "cs_test_123",
            payment_intent: "pi_test_456",
            payment_status: "paid",
            amount_total: 10000,
            currency: "usd",
            metadata: {
              "invoice_id" => "nonexistent-uuid",
              "invoice_number" => "INV-99999",
              "account_id" => account.id.to_s
            }
          )
        end

        it "logs an error and does not raise" do
          expect(Rails.logger).to receive(:error).with(/Invoice not found for checkout session/)
          expect { handler.call(event) }.not_to raise_error
        end
      end

      context "when invoice_id is missing from metadata" do
        let(:checkout_session) do
          double(
            "Stripe::Checkout::Session",
            id: "cs_test_123",
            payment_intent: "pi_test_456",
            payment_status: "paid",
            amount_total: 10000,
            currency: "usd",
            metadata: {}
          )
        end

        it "logs a warning and does not process" do
          expect(Rails.logger).to receive(:warn).with(/No invoice_id in checkout session metadata/)
          expect { handler.call(event) }.not_to raise_error
        end
      end

      context "when payment_status is not 'paid'" do
        let(:checkout_session) do
          double(
            "Stripe::Checkout::Session",
            id: "cs_test_123",
            payment_intent: "pi_test_456",
            payment_status: "unpaid",
            amount_total: 10000,
            currency: "usd",
            metadata: {
              "invoice_id" => invoice.id.to_s,
              "invoice_number" => invoice.invoice_number,
              "account_id" => account.id.to_s
            }
          )
        end

        it "does not mark the invoice as paid" do
          expect { handler.call(event) }.not_to change { invoice.reload.status }
        end
      end
    end

    context "with payment_intent.succeeded event" do
      let(:payment_intent) do
        double(
          "Stripe::PaymentIntent",
          id: "pi_test_789",
          status: "succeeded",
          amount: 10000,
          currency: "usd",
          metadata: {
            "invoice_id" => invoice.id.to_s,
            "invoice_number" => invoice.invoice_number
          }
        )
      end

      let(:event) do
        double(
          "Stripe::Event",
          type: "payment_intent.succeeded",
          data: double("data", object: payment_intent)
        )
      end

      it "marks the invoice as paid" do
        expect { handler.call(event) }.to change { invoice.reload.status }.from("sent").to("paid")
      end

      it "sets the payment_reference to the payment_intent id" do
        handler.call(event)
        expect(invoice.reload.payment_reference).to eq("pi_test_789")
      end
    end

    context "with unknown event type" do
      let(:event) do
        double(
          "Stripe::Event",
          type: "unknown.event",
          data: double("data", object: nil)
        )
      end

      it "does not raise an error" do
        expect { handler.call(event) }.not_to raise_error
      end
    end
  end
end
