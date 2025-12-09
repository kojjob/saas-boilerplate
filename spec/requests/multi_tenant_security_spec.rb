# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Multi-tenant Security", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }

  # Other account that user should NOT have access to
  let(:other_account) { create(:account) }
  let(:other_user) { create(:user, :confirmed) }
  let!(:other_membership) { create(:membership, user: other_user, account: other_account, role: "owner") }

  before do
    sign_in(user)
  end

  describe "Client isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:other_client) { create(:client, account: other_account) }

    it "cannot view another account's client" do
      get client_path(other_client)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's client" do
      patch client_path(other_client), params: { client: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_client.reload.name).not_to eq("Hacked")
    end

    it "cannot delete another account's client" do
      expect {
        delete client_path(other_client)
      }.not_to change(Client, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Project isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_project) { create(:project, account: account, client: my_client) }
    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }

    it "cannot view another account's project" do
      get project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's project" do
      patch project_path(other_project), params: { project: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_project.reload.name).not_to eq("Hacked")
    end

    it "cannot delete another account's project" do
      expect {
        delete project_path(other_project)
      }.not_to change(Project, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Invoice isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_invoice) { create(:invoice, account: account, client: my_client) }
    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_invoice) { create(:invoice, account: other_account, client: other_client) }

    it "cannot view another account's invoice" do
      get invoice_path(other_invoice)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's invoice" do
      patch invoice_path(other_invoice), params: { invoice: { notes: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_invoice.reload.notes).not_to eq("Hacked")
    end

    it "cannot delete another account's invoice" do
      other_invoice.update!(status: :draft) # Only draft can be deleted
      expect {
        delete invoice_path(other_invoice)
      }.not_to change(Invoice, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot send another account's invoice" do
      other_invoice.update!(status: :draft)
      post send_invoice_invoice_path(other_invoice)
      expect(response).to have_http_status(:not_found)
      expect(other_invoice.reload.status).to eq("draft")
    end

    it "cannot mark another account's invoice as paid" do
      other_invoice.update!(status: :sent)
      post mark_paid_invoice_path(other_invoice)
      expect(response).to have_http_status(:not_found)
      expect(other_invoice.reload.status).to eq("sent")
    end
  end

  describe "Time entry isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_project) { create(:project, account: account, client: my_client) }
    let!(:my_time_entry) { create(:time_entry, account: account, project: my_project, user: user) }

    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }
    let!(:other_time_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

    it "cannot view another account's time entry" do
      get time_entry_path(other_time_entry)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's time entry" do
      patch time_entry_path(other_time_entry), params: { time_entry: { description: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_time_entry.reload.description).not_to eq("Hacked")
    end

    it "cannot delete another account's time entry" do
      expect {
        delete time_entry_path(other_time_entry)
      }.not_to change(TimeEntry, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Material entry isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_project) { create(:project, account: account, client: my_client) }
    let!(:my_material_entry) { create(:material_entry, account: account, project: my_project, user: user) }

    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }
    let!(:other_material_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

    it "cannot view another account's material entry" do
      get material_entry_path(other_material_entry)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's material entry" do
      patch material_entry_path(other_material_entry), params: { material_entry: { description: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_material_entry.reload.description).not_to eq("Hacked")
    end

    it "cannot delete another account's material entry" do
      expect {
        delete material_entry_path(other_material_entry)
      }.not_to change(MaterialEntry, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Document isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_project) { create(:project, account: account, client: my_client) }
    let!(:my_document) { create(:document, account: account, project: my_project, uploaded_by: user) }

    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }
    let!(:other_document) { create(:document, account: other_account, project: other_project, uploaded_by: other_user) }

    it "cannot view another account's document" do
      get document_path(other_document)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot delete another account's document" do
      expect {
        delete document_path(other_document)
      }.not_to change(Document, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Estimate isolation" do
    let!(:my_client) { create(:client, account: account) }
    let!(:my_estimate) { create(:estimate, account: account, client: my_client) }

    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_estimate) { create(:estimate, account: other_account, client: other_client) }

    it "cannot view another account's estimate" do
      get estimate_path(other_estimate)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update another account's estimate" do
      patch estimate_path(other_estimate), params: { estimate: { notes: "Hacked" } }
      expect(response).to have_http_status(:not_found)
      expect(other_estimate.reload.notes).not_to eq("Hacked")
    end

    it "cannot delete another account's estimate" do
      expect {
        delete estimate_path(other_estimate)
      }.not_to change(Estimate, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Cross-account resource creation prevention" do
    let!(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }

    it "cannot create invoice for another account's client" do
      expect {
        post invoices_path, params: {
          invoice: {
            client_id: other_client.id,
            issue_date: Date.current,
            due_date: Date.current + 30.days
          }
        }
      }.not_to change(Invoice, :count)
    end

    it "cannot create project for another account's client" do
      expect {
        post projects_path, params: {
          project: {
            client_id: other_client.id,
            name: "Malicious Project"
          }
        }
      }.not_to change(Project, :count)
    end

    it "cannot create time entry for another account's project" do
      expect {
        post time_entries_path, params: {
          time_entry: {
            project_id: other_project.id,
            date: Date.current,
            hours: 8,
            description: "Malicious Entry"
          }
        }
      }.not_to change(TimeEntry, :count)
    end

    it "cannot create material entry for another account's project" do
      expect {
        post material_entries_path, params: {
          material_entry: {
            project_id: other_project.id,
            date: Date.current,
            description: "Malicious Entry",
            quantity: 1,
            unit_price: 100
          }
        }
      }.not_to change(MaterialEntry, :count)
    end
  end

  describe "Index endpoints only show current account data" do
    let!(:my_client) { create(:client, account: account, name: "My Client ABC") }
    let!(:other_client) { create(:client, account: other_account, name: "Other Client XYZ") }

    it "clients index only shows current account clients" do
      get clients_path
      expect(response.body).to include("My Client ABC")
      expect(response.body).not_to include("Other Client XYZ")
    end

    it "projects index only shows current account projects" do
      my_project = create(:project, account: account, client: my_client, name: "My Project ABC")
      other_project = create(:project, account: other_account, client: other_client, name: "Other Project XYZ")

      get projects_path
      expect(response.body).to include("My Project ABC")
      expect(response.body).not_to include("Other Project XYZ")
    end

    it "invoices index only shows current account invoices" do
      my_invoice = create(:invoice, account: account, client: my_client, invoice_number: "INV-MYABC")
      other_invoice = create(:invoice, account: other_account, client: other_client, invoice_number: "INV-OTHERXYZ")

      get invoices_path
      expect(response.body).to include("INV-MYABC")
      expect(response.body).not_to include("INV-OTHERXYZ")
    end
  end
end
