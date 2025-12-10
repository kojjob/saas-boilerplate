# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RecurringInvoices", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let(:client) { create(:client, account: account) }

  before { sign_in user }

  describe "GET /recurring_invoices" do
    it "returns a successful response" do
      get recurring_invoices_path
      expect(response).to be_successful
    end

    it "displays the user's recurring invoices" do
      recurring = create(:recurring_invoice, account: account, client: client, name: "Monthly Retainer")
      other_account = create(:account)
      other_client = create(:client, account: other_account)
      other_recurring = create(:recurring_invoice, account: other_account, client: other_client, name: "Other Account Retainer")

      get recurring_invoices_path

      expect(response.body).to include("Monthly Retainer")
      expect(response.body).not_to include("Other Account Retainer")
    end
  end

  describe "GET /recurring_invoices/:id" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client) }

    it "returns a successful response" do
      get recurring_invoice_path(recurring_invoice)
      expect(response).to be_successful
    end

    it "displays the recurring invoice details" do
      get recurring_invoice_path(recurring_invoice)
      expect(response.body).to include(recurring_invoice.name)
    end

    it "returns 404 for another account's recurring invoice" do
      other_account = create(:account)
      other_client = create(:client, account: other_account)
      other_recurring = create(:recurring_invoice, account: other_account, client: other_client)

      get recurring_invoice_path(other_recurring)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /recurring_invoices/new" do
    it "returns a successful response" do
      get new_recurring_invoice_path
      expect(response).to be_successful
    end
  end

  describe "POST /recurring_invoices" do
    let(:valid_attributes) do
      {
        name: "Monthly Consulting",
        client_id: client.id,
        frequency: "monthly",
        start_date: Date.current,
        payment_terms: 30,
        currency: "USD",
        tax_rate: 10.0,
        auto_send: false,
        line_items_attributes: [
          {
            description: "Consulting Services",
            quantity: 10,
            unit_price: 150.00
          }
        ]
      }
    end

    it "creates a new recurring invoice" do
      expect {
        post recurring_invoices_path, params: { recurring_invoice: valid_attributes }
      }.to change(RecurringInvoice, :count).by(1)
    end

    it "creates line items" do
      expect {
        post recurring_invoices_path, params: { recurring_invoice: valid_attributes }
      }.to change(RecurringInvoiceLineItem, :count).by(1)
    end

    it "redirects to the recurring invoice" do
      post recurring_invoices_path, params: { recurring_invoice: valid_attributes }
      expect(response).to redirect_to(recurring_invoice_path(RecurringInvoice.last))
    end

    context "with invalid attributes" do
      it "renders the new template" do
        post recurring_invoices_path, params: { recurring_invoice: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /recurring_invoices/:id/edit" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client) }

    it "returns a successful response" do
      get edit_recurring_invoice_path(recurring_invoice)
      expect(response).to be_successful
    end
  end

  describe "PATCH /recurring_invoices/:id" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client) }

    it "updates the recurring invoice" do
      patch recurring_invoice_path(recurring_invoice), params: {
        recurring_invoice: { name: "Updated Name" }
      }
      expect(recurring_invoice.reload.name).to eq("Updated Name")
    end

    it "redirects to the recurring invoice" do
      patch recurring_invoice_path(recurring_invoice), params: {
        recurring_invoice: { name: "Updated Name" }
      }
      expect(response).to redirect_to(recurring_invoice_path(recurring_invoice))
    end
  end

  describe "DELETE /recurring_invoices/:id" do
    let!(:recurring_invoice) { create(:recurring_invoice, account: account, client: client) }

    it "destroys the recurring invoice" do
      expect {
        delete recurring_invoice_path(recurring_invoice)
      }.to change(RecurringInvoice, :count).by(-1)
    end

    it "redirects to the index" do
      delete recurring_invoice_path(recurring_invoice)
      expect(response).to redirect_to(recurring_invoices_path)
    end
  end

  describe "POST /recurring_invoices/:id/pause" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client, status: :active) }

    it "pauses the recurring invoice" do
      post pause_recurring_invoice_path(recurring_invoice)
      expect(recurring_invoice.reload).to be_paused
    end

    it "redirects to the recurring invoice" do
      post pause_recurring_invoice_path(recurring_invoice)
      expect(response).to redirect_to(recurring_invoice_path(recurring_invoice))
    end
  end

  describe "POST /recurring_invoices/:id/resume" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client, status: :paused) }

    it "resumes the recurring invoice" do
      post resume_recurring_invoice_path(recurring_invoice)
      expect(recurring_invoice.reload).to be_active
    end
  end

  describe "POST /recurring_invoices/:id/cancel" do
    let(:recurring_invoice) { create(:recurring_invoice, account: account, client: client, status: :active) }

    it "cancels the recurring invoice" do
      post cancel_recurring_invoice_path(recurring_invoice)
      expect(recurring_invoice.reload).to be_cancelled
    end
  end

  describe "POST /recurring_invoices/:id/generate_now" do
    let(:recurring_invoice) do
      create(:recurring_invoice, account: account, client: client, status: :active, next_occurrence_date: Date.current)
    end

    before do
      create(:recurring_invoice_line_item, recurring_invoice: recurring_invoice)
    end

    it "generates an invoice immediately" do
      expect {
        post generate_now_recurring_invoice_path(recurring_invoice)
      }.to change(Invoice, :count).by(1)
    end

    it "redirects to the generated invoice" do
      post generate_now_recurring_invoice_path(recurring_invoice)
      expect(response).to redirect_to(invoice_path(Invoice.last))
    end

    context "when generation fails" do
      before do
        recurring_invoice.update!(next_occurrence_date: Date.current + 7.days)
      end

      it "redirects back with an error" do
        post generate_now_recurring_invoice_path(recurring_invoice)
        expect(response).to redirect_to(recurring_invoice_path(recurring_invoice))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
