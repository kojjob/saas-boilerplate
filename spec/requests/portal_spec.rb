# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portal", type: :request do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account, portal_enabled: true) }

  before do
    client.generate_portal_token!
  end

  describe "GET /portal/:token (dashboard)" do
    context "with valid token" do
      it "returns http success" do
        get portal_dashboard_path(token: client.portal_token)
        expect(response).to have_http_status(:success)
      end

      it "displays client information" do
        get portal_dashboard_path(token: client.portal_token)
        expect(response.body).to include(client.name)
      end

      it "displays recent invoices" do
        invoice = create(:invoice, client: client, account: account)
        get portal_dashboard_path(token: client.portal_token)
        expect(response.body).to include(invoice.invoice_number)
      end

      it "displays recent projects" do
        project = create(:project, client: client, account: account)
        get portal_dashboard_path(token: client.portal_token)
        expect(response.body).to include(project.name)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_dashboard_path(token: "invalid_token")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with disabled portal access" do
      before do
        client.update!(portal_enabled: false)
      end

      it "returns not found" do
        get portal_dashboard_path(token: client.portal_token)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with revoked token" do
      before do
        client.revoke_portal_token!
      end

      it "returns not found" do
        get portal_dashboard_path(token: "")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/invoices" do
    context "with valid token" do
      it "returns http success" do
        get portal_invoices_path(token: client.portal_token)
        expect(response).to have_http_status(:success)
      end

      it "displays all client invoices" do
        invoice1 = create(:invoice, client: client, account: account, status: :sent)
        invoice2 = create(:invoice, client: client, account: account, status: :paid)

        get portal_invoices_path(token: client.portal_token)

        expect(response.body).to include(invoice1.invoice_number)
        expect(response.body).to include(invoice2.invoice_number)
      end

      it "does not display other clients invoices" do
        other_client = create(:client, account: account)
        other_invoice = create(:invoice, client: other_client, account: account)

        get portal_invoices_path(token: client.portal_token)

        expect(response.body).not_to include(other_invoice.invoice_number)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_invoices_path(token: "invalid_token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/invoices/:id" do
    let(:invoice) { create(:invoice, client: client, account: account) }

    context "with valid token and invoice" do
      it "returns http success" do
        get portal_invoice_path(token: client.portal_token, id: invoice.id)
        expect(response).to have_http_status(:success)
      end

      it "displays invoice details" do
        get portal_invoice_path(token: client.portal_token, id: invoice.id)
        expect(response.body).to include(invoice.invoice_number)
      end
    end

    context "with invoice belonging to different client" do
      let(:other_client) { create(:client, account: account) }
      let(:other_invoice) { create(:invoice, client: other_client, account: account) }

      it "returns not found" do
        get portal_invoice_path(token: client.portal_token, id: other_invoice.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_invoice_path(token: "invalid_token", id: invoice.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/invoices/:id/download" do
    let(:invoice) { create(:invoice, client: client, account: account, status: :sent) }

    context "with valid token and invoice" do
      it "returns a PDF file" do
        get portal_download_invoice_path(token: client.portal_token, id: invoice.id)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
      end

      it "sets correct filename" do
        get portal_download_invoice_path(token: client.portal_token, id: invoice.id)
        expect(response.headers["Content-Disposition"]).to include("Invoice")
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_download_invoice_path(token: "invalid_token", id: invoice.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/estimates" do
    context "with valid token" do
      it "returns http success" do
        get portal_estimates_path(token: client.portal_token)
        expect(response).to have_http_status(:success)
      end

      it "displays all client estimates" do
        estimate1 = create(:estimate, client: client, account: account, status: :sent)
        estimate2 = create(:estimate, client: client, account: account, status: :accepted)

        get portal_estimates_path(token: client.portal_token)

        expect(response.body).to include(estimate1.estimate_number)
        expect(response.body).to include(estimate2.estimate_number)
      end

      it "does not display other clients estimates" do
        other_client = create(:client, account: account)
        other_estimate = create(:estimate, client: other_client, account: account)

        get portal_estimates_path(token: client.portal_token)

        expect(response.body).not_to include(other_estimate.estimate_number)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_estimates_path(token: "invalid_token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/estimates/:id" do
    let(:estimate) { create(:estimate, client: client, account: account) }

    context "with valid token and estimate" do
      it "returns http success" do
        get portal_estimate_path(token: client.portal_token, id: estimate.id)
        expect(response).to have_http_status(:success)
      end

      it "displays estimate details" do
        get portal_estimate_path(token: client.portal_token, id: estimate.id)
        expect(response.body).to include(estimate.estimate_number)
      end
    end

    context "with estimate belonging to different client" do
      let(:other_client) { create(:client, account: account) }
      let(:other_estimate) { create(:estimate, client: other_client, account: account) }

      it "returns not found" do
        get portal_estimate_path(token: client.portal_token, id: other_estimate.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_estimate_path(token: "invalid_token", id: estimate.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/estimates/:id/download" do
    let(:estimate) { create(:estimate, client: client, account: account, status: :sent) }

    context "with valid token and estimate" do
      it "returns a PDF file" do
        get portal_download_estimate_path(token: client.portal_token, id: estimate.id)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
      end

      it "sets correct filename" do
        get portal_download_estimate_path(token: client.portal_token, id: estimate.id)
        expect(response.headers["Content-Disposition"]).to include("Estimate")
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_download_estimate_path(token: "invalid_token", id: estimate.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/projects" do
    context "with valid token" do
      it "returns http success" do
        get portal_projects_path(token: client.portal_token)
        expect(response).to have_http_status(:success)
      end

      it "displays all client projects" do
        project1 = create(:project, client: client, account: account, status: :active)
        project2 = create(:project, client: client, account: account, status: :completed)

        get portal_projects_path(token: client.portal_token)

        expect(response.body).to include(project1.name)
        expect(response.body).to include(project2.name)
      end

      it "does not display other clients projects" do
        other_client = create(:client, account: account)
        other_project = create(:project, client: other_client, account: account)

        get portal_projects_path(token: client.portal_token)

        expect(response.body).not_to include(other_project.name)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_projects_path(token: "invalid_token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /portal/:token/projects/:id" do
    let(:project) { create(:project, client: client, account: account) }

    context "with valid token and project" do
      it "returns http success" do
        get portal_project_path(token: client.portal_token, id: project.id)
        expect(response).to have_http_status(:success)
      end

      it "displays project details" do
        get portal_project_path(token: client.portal_token, id: project.id)
        expect(response.body).to include(project.name)
      end

      it "displays project invoices" do
        invoice = create(:invoice, client: client, account: account, project: project)
        get portal_project_path(token: client.portal_token, id: project.id)
        expect(response.body).to include(invoice.invoice_number)
      end
    end

    context "with project belonging to different client" do
      let(:other_client) { create(:client, account: account) }
      let(:other_project) { create(:project, client: other_client, account: account) }

      it "returns not found" do
        get portal_project_path(token: client.portal_token, id: other_project.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get portal_project_path(token: "invalid_token", id: project.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
