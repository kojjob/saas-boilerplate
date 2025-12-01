# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Clients", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }

  before do
    sign_in(user)
  end

  describe "GET /clients" do
    let!(:clients) { create_list(:client, 3, account: account) }

    it "returns http success" do
      get clients_path

      expect(response).to have_http_status(:ok)
    end

    it "displays clients list" do
      get clients_path

      clients.each do |client|
        expect(response.body).to include(client.name)
      end
    end

    it "only shows clients from current account" do
      other_account = create(:account)
      other_client = create(:client, account: other_account, name: "Other Account Client")

      get clients_path

      expect(response.body).not_to include("Other Account Client")
    end

    context "with search parameter" do
      let!(:searchable_client) { create(:client, account: account, name: "Searchable Client") }

      it "filters clients by search query" do
        get clients_path, params: { search: "Searchable" }

        expect(response.body).to include("Searchable Client")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get clients_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /clients/:id" do
    let!(:client) { create(:client, account: account) }

    it "returns http success" do
      get client_path(client)

      expect(response).to have_http_status(:ok)
    end

    it "displays client details" do
      get client_path(client)

      expect(response.body).to include(client.name)
      expect(response.body).to include(client.email)
    end

    context "when client belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }

      it "returns not found" do
        get client_path(other_client)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with recent projects and invoices" do
      let!(:projects) { create_list(:project, 2, client: client, account: account) }
      let!(:invoices) { create_list(:invoice, 2, client: client, account: account) }

      it "displays recent projects" do
        get client_path(client)

        projects.each do |project|
          expect(response.body).to include(project.name)
        end
      end

      it "displays recent invoices" do
        get client_path(client)

        invoices.each do |invoice|
          expect(response.body).to include(invoice.invoice_number)
        end
      end
    end
  end

  describe "GET /clients/new" do
    it "returns http success" do
      get new_client_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new client form" do
      get new_client_path

      expect(response.body).to include("Add client")
    end
  end

  describe "POST /clients" do
    let(:valid_params) do
      {
        client: {
          name: "John Doe",
          email: "john@example.com",
          phone: "555-123-4567",
          company: "Doe Enterprises"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new client" do
        expect {
          post clients_path, params: valid_params
        }.to change(Client, :count).by(1)
      end

      it "redirects to clients index" do
        post clients_path, params: valid_params

        expect(response).to redirect_to(clients_path)
      end

      it "displays success message" do
        post clients_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end

      it "associates client with current account" do
        post clients_path, params: valid_params

        expect(Client.last.account).to eq(account)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          client: {
            name: "",
            email: "invalid-email"
          }
        }
      end

      it "does not create a new client" do
        expect {
          post clients_path, params: invalid_params
        }.not_to change(Client, :count)
      end

      it "returns unprocessable entity status" do
        post clients_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with duplicate email in same account" do
      let!(:existing_client) { create(:client, account: account, email: "john@example.com") }

      it "does not create a new client" do
        expect {
          post clients_path, params: valid_params
        }.not_to change(Client, :count)
      end

      it "returns unprocessable entity status" do
        post clients_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /clients/:id/edit" do
    let!(:client) { create(:client, account: account) }

    it "returns http success" do
      get edit_client_path(client)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with client data" do
      get edit_client_path(client)

      expect(response.body).to include("Edit client")
      expect(response.body).to include(client.name)
    end

    context "when client belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }

      it "returns not found" do
        get edit_client_path(other_client)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /clients/:id" do
    let!(:client) { create(:client, account: account) }
    let(:valid_params) { { client: { name: "Updated Name" } } }

    context "with valid parameters" do
      it "updates the client" do
        patch client_path(client), params: valid_params

        expect(client.reload.name).to eq("Updated Name")
      end

      it "redirects to clients index" do
        patch client_path(client), params: valid_params

        expect(response).to redirect_to(clients_path)
      end

      it "displays success message" do
        patch client_path(client), params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { client: { name: "", email: "invalid" } } }

      it "does not update the client" do
        original_name = client.name
        patch client_path(client), params: invalid_params

        expect(client.reload.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch client_path(client), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when client belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }

      it "returns not found" do
        patch client_path(other_client), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /clients/:id" do
    let!(:client) { create(:client, account: account) }

    context "when client has no projects or invoices" do
      it "deletes the client" do
        expect {
          delete client_path(client)
        }.to change(Client, :count).by(-1)
      end

      it "redirects to clients index" do
        delete client_path(client)

        expect(response).to redirect_to(clients_path)
      end

      it "displays success message" do
        delete client_path(client)

        expect(flash[:notice]).to include("successfully deleted")
      end
    end

    context "when client has projects" do
      let!(:project) { create(:project, client: client, account: account) }

      it "does not delete the client" do
        expect {
          delete client_path(client)
        }.not_to change(Client, :count)
      end

      it "redirects to clients index with alert" do
        delete client_path(client)

        expect(response).to redirect_to(clients_path)
        expect(flash[:alert]).to include("Cannot delete")
      end
    end

    context "when client has invoices" do
      let!(:invoice) { create(:invoice, client: client, account: account) }

      it "does not delete the client" do
        expect {
          delete client_path(client)
        }.not_to change(Client, :count)
      end

      it "redirects to clients index with alert" do
        delete client_path(client)

        expect(response).to redirect_to(clients_path)
        expect(flash[:alert]).to include("Cannot delete")
      end
    end

    context "when client belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }

      it "returns not found" do
        delete client_path(other_client)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /clients/:id/projects" do
    let!(:client) { create(:client, account: account) }
    let!(:projects) { create_list(:project, 3, client: client, account: account) }

    it "returns http success" do
      get projects_client_path(client)

      expect(response).to have_http_status(:ok)
    end

    it "displays client projects" do
      get projects_client_path(client)

      projects.each do |project|
        expect(response.body).to include(project.name)
      end
    end
  end

  describe "GET /clients/:id/invoices" do
    let!(:client) { create(:client, account: account) }
    let!(:invoices) { create_list(:invoice, 3, client: client, account: account) }

    it "returns http success" do
      get invoices_client_path(client)

      expect(response).to have_http_status(:ok)
    end

    it "displays client invoices" do
      get invoices_client_path(client)

      invoices.each do |invoice|
        expect(response.body).to include(invoice.invoice_number)
      end
    end
  end
end
