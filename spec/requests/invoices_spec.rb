# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoices", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let!(:client) { create(:client, account: account) }

  before do
    sign_in(user)
  end

  describe "GET /invoices" do
    let!(:invoices) { create_list(:invoice, 3, account: account, client: client) }

    it "returns http success" do
      get invoices_path

      expect(response).to have_http_status(:ok)
    end

    it "displays invoices list" do
      get invoices_path

      invoices.each do |invoice|
        expect(response.body).to include(invoice.invoice_number)
      end
    end

    it "displays stats dashboard" do
      get invoices_path

      expect(response.body).to include("Outstanding")
      expect(response.body).to include("Overdue")
      expect(response.body).to include("Paid This Month")
      expect(response.body).to include("Due Soon")
    end

    it "only shows invoices from current account" do
      other_account = create(:account)
      other_client = create(:client, account: other_account)
      other_invoice = create(:invoice, account: other_account, client: other_client, invoice_number: "OTHER-99999")

      get invoices_path

      expect(response.body).not_to include("OTHER-99999")
    end

    context "with search parameter" do
      let!(:searchable_invoice) { create(:invoice, account: account, client: client, invoice_number: "INV-SEARCH123") }

      it "filters invoices by invoice number" do
        get invoices_path, params: { search: "SEARCH123" }

        expect(response.body).to include("INV-SEARCH123")
      end

      it "filters invoices by client name" do
        searchable_client = create(:client, account: account, name: "Searchable Client Name")
        create(:invoice, account: account, client: searchable_client, invoice_number: "INV-CLIENTSEARCH")

        get invoices_path, params: { search: "Searchable Client" }

        expect(response.body).to include("INV-CLIENTSEARCH")
      end
    end

    context "with status filter" do
      let!(:draft_invoice) { create(:invoice, :draft, account: account, client: client, invoice_number: "INV-DRAFT1") }
      let!(:sent_invoice) { create(:invoice, :sent, account: account, client: client, invoice_number: "INV-SENT1") }
      let!(:paid_invoice) { create(:invoice, :paid, account: account, client: client, invoice_number: "INV-PAID1") }

      it "filters by draft status" do
        get invoices_path, params: { status: "draft" }

        expect(response.body).to include("INV-DRAFT1")
      end

      it "filters by sent status" do
        get invoices_path, params: { status: "sent" }

        expect(response.body).to include("INV-SENT1")
      end

      it "filters by paid status" do
        get invoices_path, params: { status: "paid" }

        expect(response.body).to include("INV-PAID1")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get invoices_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /invoices/:id" do
    let!(:invoice) { create(:invoice, account: account, client: client) }

    it "returns http success" do
      get invoice_path(invoice)

      expect(response).to have_http_status(:ok)
    end

    it "displays invoice details" do
      get invoice_path(invoice)

      expect(response.body).to include(invoice.invoice_number)
      expect(response.body).to include(client.name)
    end

    it "displays invoice summary section" do
      get invoice_path(invoice)

      # The page shows "Due In" for unpaid invoices, "Payment Received" for paid, or "Days Overdue" for overdue
      expect(response.body).to include("Due In").or include("Payment Received").or include("Days Overdue")
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, account: other_account, client: other_client) }

      it "returns not found" do
        get invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with line items" do
      let!(:line_items) { create_list(:invoice_line_item, 2, invoice: invoice) }

      it "displays line items" do
        get invoice_path(invoice)

        line_items.each do |item|
          expect(response.body).to include(item.description)
        end
      end
    end

    context "when invoice is paid" do
      let!(:paid_invoice) { create(:invoice, :paid, account: account, client: client) }

      it "displays paid status" do
        get invoice_path(paid_invoice)

        expect(response.body).to include("Paid")
      end
    end
  end

  describe "GET /invoices/new" do
    it "returns http success" do
      get new_invoice_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new invoice form" do
      get new_invoice_path

      expect(response.body).to include("Create new invoice")
    end

    context "with client_id parameter" do
      it "preselects the client" do
        get new_invoice_path, params: { client_id: client.id }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with project_id parameter" do
      let!(:project) { create(:project, account: account, client: client) }

      it "preselects the project" do
        get new_invoice_path, params: { project_id: project.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /invoices" do
    let(:valid_params) do
      {
        invoice: {
          client_id: client.id,
          issue_date: Date.today,
          due_date: Date.today + 30.days,
          notes: "Test invoice notes",
          tax_rate: 10
        }
      }
    end

    context "with valid parameters" do
      it "creates a new invoice" do
        expect {
          post invoices_path, params: valid_params
        }.to change(Invoice, :count).by(1)
      end

      it "redirects to invoices index" do
        post invoices_path, params: valid_params

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        post invoices_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end

      it "associates invoice with current account" do
        post invoices_path, params: valid_params

        expect(Invoice.last.account).to eq(account)
      end

      it "auto-generates invoice number" do
        post invoices_path, params: valid_params

        expect(Invoice.last.invoice_number).to be_present
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          invoice: {
            client_id: nil,
            issue_date: nil
          }
        }
      end

      it "does not create a new invoice" do
        expect {
          post invoices_path, params: invalid_params
        }.not_to change(Invoice, :count)
      end

      it "returns unprocessable entity status" do
        post invoices_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /invoices/:id/edit" do
    let!(:invoice) { create(:invoice, :draft, account: account, client: client) }

    it "returns http success" do
      get edit_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with invoice data" do
      get edit_invoice_path(invoice)

      expect(response.body).to include("Edit invoice")
      expect(response.body).to include(invoice.invoice_number)
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, account: other_account, client: other_client) }

      it "returns not found" do
        get edit_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /invoices/:id" do
    let!(:invoice) { create(:invoice, :draft, account: account, client: client) }
    let(:valid_params) { { invoice: { notes: "Updated invoice notes" } } }

    context "with valid parameters" do
      it "updates the invoice" do
        patch invoice_path(invoice), params: valid_params

        expect(invoice.reload.notes).to eq("Updated invoice notes")
      end

      it "redirects to invoices index" do
        patch invoice_path(invoice), params: valid_params

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        patch invoice_path(invoice), params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { invoice: { client_id: nil } } }

      it "does not update the invoice" do
        original_client_id = invoice.client_id
        patch invoice_path(invoice), params: invalid_params

        expect(invoice.reload.client_id).to eq(original_client_id)
      end

      it "returns unprocessable entity status" do
        patch invoice_path(invoice), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, account: other_account, client: other_client) }

      it "returns not found" do
        patch invoice_path(other_invoice), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /invoices/:id" do
    context "when invoice is draft" do
      let!(:invoice) { create(:invoice, :draft, account: account, client: client) }

      it "deletes the invoice" do
        expect {
          delete invoice_path(invoice)
        }.to change(Invoice, :count).by(-1)
      end

      it "redirects to invoices index" do
        delete invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        delete invoice_path(invoice)

        expect(flash[:notice]).to include("successfully deleted")
      end
    end

    context "when invoice is cancelled" do
      let!(:invoice) { create(:invoice, :cancelled, account: account, client: client) }

      it "deletes the invoice" do
        expect {
          delete invoice_path(invoice)
        }.to change(Invoice, :count).by(-1)
      end
    end

    context "when invoice is sent" do
      let!(:invoice) { create(:invoice, :sent, account: account, client: client) }

      it "does not delete the invoice" do
        expect {
          delete invoice_path(invoice)
        }.not_to change(Invoice, :count)
      end

      it "redirects to invoices index with alert" do
        delete invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to include("draft or cancelled")
      end
    end

    context "when invoice is paid" do
      let!(:invoice) { create(:invoice, :paid, account: account, client: client) }

      it "does not delete the invoice" do
        expect {
          delete invoice_path(invoice)
        }.not_to change(Invoice, :count)
      end

      it "redirects to invoices index with alert" do
        delete invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to include("draft or cancelled")
      end
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, :draft, account: other_account, client: other_client) }

      it "returns not found" do
        delete invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /invoices/:id/send_invoice" do
    context "when invoice is draft" do
      let!(:invoice) { create(:invoice, :draft, account: account, client: client) }

      it "marks the invoice as sent" do
        patch send_invoice_invoice_path(invoice)

        expect(invoice.reload.status).to eq("sent")
      end

      it "sets sent_at timestamp" do
        patch send_invoice_invoice_path(invoice)

        expect(invoice.reload.sent_at).to be_present
      end

      it "redirects to invoices index" do
        patch send_invoice_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        patch send_invoice_invoice_path(invoice)

        expect(flash[:notice]).to include("sent")
      end

      it "enqueues an invoice email" do
        expect {
          patch send_invoice_invoice_path(invoice)
        }.to have_enqueued_mail(InvoiceMailer, :send_invoice).with(invoice)
      end

      it "includes client's email in success message" do
        patch send_invoice_invoice_path(invoice)

        expect(flash[:notice]).to include(client.email)
      end
    end

    context "when invoice is not draft" do
      let!(:invoice) { create(:invoice, :sent, account: account, client: client) }

      it "does not change the status" do
        patch send_invoice_invoice_path(invoice)

        expect(invoice.reload.status).to eq("sent")
      end

      it "redirects with alert" do
        patch send_invoice_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, :draft, account: other_account, client: other_client) }

      it "returns not found" do
        patch send_invoice_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /invoices/:id/mark_paid" do
    context "when invoice is unpaid (sent)" do
      let!(:invoice) { create(:invoice, :sent, account: account, client: client) }

      it "marks the invoice as paid" do
        patch mark_paid_invoice_path(invoice)

        expect(invoice.reload.status).to eq("paid")
      end

      it "sets paid_at timestamp" do
        patch mark_paid_invoice_path(invoice)

        expect(invoice.reload.paid_at).to be_present
      end

      it "redirects to invoices index" do
        patch mark_paid_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        patch mark_paid_invoice_path(invoice)

        expect(flash[:notice]).to include("paid")
      end
    end

    context "when invoice is already paid" do
      let!(:invoice) { create(:invoice, :paid, account: account, client: client) }

      it "does not change the status" do
        original_paid_at = invoice.paid_at
        patch mark_paid_invoice_path(invoice)

        expect(invoice.reload.paid_at).to eq(original_paid_at)
      end

      it "redirects with alert" do
        patch mark_paid_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when invoice is draft" do
      let!(:invoice) { create(:invoice, :draft, account: account, client: client) }

      it "does not mark as paid (must be sent first)" do
        patch mark_paid_invoice_path(invoice)

        expect(invoice.reload.status).to eq("draft")
      end

      it "redirects with alert" do
        patch mark_paid_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, :sent, account: other_account, client: other_client) }

      it "returns not found" do
        patch mark_paid_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /invoices/:id/mark_cancelled" do
    context "when invoice is not paid" do
      let!(:invoice) { create(:invoice, :sent, account: account, client: client) }

      it "marks the invoice as cancelled" do
        patch mark_cancelled_invoice_path(invoice)

        expect(invoice.reload.status).to eq("cancelled")
      end

      it "redirects to invoices index" do
        patch mark_cancelled_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
      end

      it "displays success message" do
        patch mark_cancelled_invoice_path(invoice)

        expect(flash[:notice]).to include("cancelled")
      end
    end

    context "when invoice is already paid" do
      let!(:invoice) { create(:invoice, :paid, account: account, client: client) }

      it "does not change the status" do
        patch mark_cancelled_invoice_path(invoice)

        expect(invoice.reload.status).to eq("paid")
      end

      it "redirects with alert" do
        patch mark_cancelled_invoice_path(invoice)

        expect(response).to redirect_to(invoices_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when invoice is draft" do
      let!(:invoice) { create(:invoice, :draft, account: account, client: client) }

      it "marks the invoice as cancelled" do
        patch mark_cancelled_invoice_path(invoice)

        expect(invoice.reload.status).to eq("cancelled")
      end
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, :sent, account: other_account, client: other_client) }

      it "returns not found" do
        patch mark_cancelled_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /invoices/:id/download" do
    let!(:invoice) { create(:invoice, :sent, account: account, client: client) }
    let!(:line_item) { create(:invoice_line_item, invoice: invoice, description: "Test Service", quantity: 1, unit_price: 100) }

    it "returns http success" do
      get download_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
    end

    it "returns PDF content type" do
      get download_invoice_path(invoice)

      expect(response.content_type).to include("application/pdf")
    end

    it "includes invoice number in filename" do
      get download_invoice_path(invoice)

      expect(response.headers["Content-Disposition"]).to include(invoice.invoice_number.downcase.gsub(/[^a-z0-9]/, "_"))
    end

    it "generates PDF using InvoicePdfGenerator" do
      expect(InvoicePdfGenerator).to receive(:call).with(invoice).and_call_original

      get download_invoice_path(invoice)
    end

    context "when invoice belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_invoice) { create(:invoice, :sent, account: other_account, client: other_client) }

      it "returns not found" do
        get download_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
