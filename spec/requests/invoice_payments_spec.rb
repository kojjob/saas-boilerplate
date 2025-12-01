# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoice Payments", type: :request do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }
  let(:invoice) { create(:invoice, account: account, client: client, status: :sent, total_amount: 150.00) }

  describe "GET /pay/:payment_token" do
    context "with valid payment token" do
      it "renders the payment page" do
        get pay_invoice_path(payment_token: invoice.payment_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(invoice.invoice_number)
        expect(response.body).to include("$150.00")
      end

      it "does not require authentication" do
        get pay_invoice_path(payment_token: invoice.payment_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid payment token" do
      it "returns 404" do
        get pay_invoice_path(payment_token: "invalid-token")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when invoice is already paid" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :paid) }

      it "shows paid status" do
        get pay_invoice_path(payment_token: invoice.payment_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("paid")
      end
    end

    context "when invoice is cancelled" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :cancelled) }

      it "shows cancelled status" do
        get pay_invoice_path(payment_token: invoice.payment_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("cancelled")
      end
    end
  end

  describe "POST /pay/:payment_token/checkout" do
    context "with valid payment token and unpaid invoice" do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(
          double(url: "https://checkout.stripe.com/test-session")
        )
      end

      it "creates a Stripe checkout session and redirects", :skip_stripe do
        post pay_invoice_checkout_path(payment_token: invoice.payment_token)

        expect(response).to redirect_to("https://checkout.stripe.com/test-session")
      end
    end

    context "when invoice is already paid" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :paid) }

      it "redirects back with error" do
        post pay_invoice_checkout_path(payment_token: invoice.payment_token)

        expect(response).to redirect_to(pay_invoice_path(payment_token: invoice.payment_token))
        follow_redirect!
        expect(response.body).to include("already been paid")
      end
    end

    context "when Stripe is not configured" do
      before do
        allow_any_instance_of(InvoicePaymentsController).to receive(:stripe_configured?).and_return(false)
      end

      it "returns an error" do
        post pay_invoice_checkout_path(payment_token: invoice.payment_token)

        expect(response).to redirect_to(pay_invoice_path(payment_token: invoice.payment_token))
        follow_redirect!
        expect(response.body).to include("not configured")
      end
    end
  end

  describe "GET /pay/:payment_token/success" do
    it "shows payment success page" do
      get pay_invoice_success_path(payment_token: invoice.payment_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thank you")
    end
  end

  describe "GET /pay/:payment_token/cancel" do
    it "shows payment cancelled page" do
      get pay_invoice_cancel_path(payment_token: invoice.payment_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("cancelled")
    end
  end
end
