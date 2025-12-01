# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let!(:client) { create(:client, account: account) }
  let!(:project) { create(:project, account: account, client: client) }

  before do
    sign_in(user)
  end

  describe "GET /documents" do
    let!(:documents) { create_list(:document, 3, :with_pdf, account: account, uploaded_by: user) }

    it "returns http success" do
      get documents_path

      expect(response).to have_http_status(:ok)
    end

    it "displays documents list" do
      get documents_path

      documents.each do |document|
        expect(response.body).to include(document.name)
      end
    end

    it "only shows documents from current account" do
      other_account = create(:account)
      other_user = create(:user, :confirmed)
      other_document = create(:document, :with_pdf, account: other_account, uploaded_by: other_user, name: "Other Account Document")

      get documents_path

      expect(response.body).not_to include("Other Account Document")
    end

    context "with search parameter" do
      let!(:searchable_document) { create(:document, :with_pdf, account: account, uploaded_by: user, name: "Searchable Document") }

      it "filters documents by search query" do
        get documents_path, params: { search: "Searchable" }

        expect(response.body).to include("Searchable Document")
      end
    end

    context "with category filter" do
      let!(:contract_document) { create(:document, :contract, :with_pdf, account: account, uploaded_by: user, name: "Contract Document") }
      let!(:receipt_document) { create(:document, :receipt, :with_pdf, account: account, uploaded_by: user, name: "Receipt Document") }

      it "filters documents by category" do
        get documents_path, params: { category: "contract" }

        expect(response.body).to include("Contract Document")
      end

      it "shows all documents when category is 'all'" do
        get documents_path, params: { category: "all" }

        expect(response.body).to include("Contract Document")
        expect(response.body).to include("Receipt Document")
      end
    end

    context "with project filter" do
      let!(:project_document) { create(:document, :with_pdf, :with_project, account: account, uploaded_by: user, project: project, name: "Project Document") }
      let!(:no_project_document) { create(:document, :with_pdf, account: account, uploaded_by: user, project: nil, name: "No Project Document") }

      it "filters documents by project" do
        get documents_path, params: { project_id: project.id }

        expect(response.body).to include("Project Document")
        expect(response.body).not_to include("No Project Document")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get documents_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /documents/:id" do
    let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user) }

    it "returns http success" do
      get document_path(document)

      expect(response).to have_http_status(:ok)
    end

    it "displays document details" do
      get document_path(document)

      expect(response.body).to include(document.name)
      expect(response.body).to include(document.category.humanize)
    end

    context "when document has a description" do
      let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user, description: "Test description") }

      it "displays the description" do
        get document_path(document)

        expect(response.body).to include("Test description")
      end
    end

    context "when document belongs to a project" do
      let!(:document) { create(:document, :with_pdf, :with_project, account: account, uploaded_by: user, project: project) }

      it "displays project information" do
        get document_path(document)

        expect(response.body).to include(project.name)
      end
    end

    context "when document belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_document) { create(:document, :with_pdf, account: other_account, uploaded_by: other_user) }

      it "returns not found" do
        get document_path(other_document)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /documents/new" do
    it "returns http success" do
      get new_document_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new document form" do
      get new_document_path

      expect(response.body).to include("Upload document")
    end

    context "with project_id parameter" do
      it "preselects the project" do
        get new_document_path, params: { project_id: project.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /documents" do
    let(:valid_params) do
      {
        document: {
          name: "Test Document",
          category: "contract",
          description: "A test document",
          project_id: project.id,
          file: fixture_file_upload("spec/fixtures/files/test.txt", "text/plain")
        }
      }
    end

    context "with valid parameters" do
      before do
        # Create the fixture file if it doesn't exist
        FileUtils.mkdir_p("spec/fixtures/files")
        File.write("spec/fixtures/files/test.txt", "Test content") unless File.exist?("spec/fixtures/files/test.txt")
      end

      it "creates a new document" do
        expect {
          post documents_path, params: valid_params
        }.to change(Document, :count).by(1)
      end

      it "redirects to documents index" do
        post documents_path, params: valid_params

        expect(response).to redirect_to(documents_path)
      end

      it "displays success message" do
        post documents_path, params: valid_params

        expect(flash[:notice]).to include("successfully")
      end

      it "associates document with current account" do
        post documents_path, params: valid_params

        expect(Document.last.account).to eq(account)
      end

      it "associates document with current user as uploaded_by" do
        post documents_path, params: valid_params

        expect(Document.last.uploaded_by).to eq(user)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          document: {
            name: "",
            category: "contract"
          }
        }
      end

      it "does not create a new document" do
        expect {
          post documents_path, params: invalid_params
        }.not_to change(Document, :count)
      end

      it "returns unprocessable entity status" do
        post documents_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /documents/:id/edit" do
    let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user) }

    it "returns http success" do
      get edit_document_path(document)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with document data" do
      get edit_document_path(document)

      expect(response.body).to include("Edit document")
      expect(response.body).to include(document.name)
    end

    context "when document belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_document) { create(:document, :with_pdf, account: other_account, uploaded_by: other_user) }

      it "returns not found" do
        get edit_document_path(other_document)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /documents/:id" do
    let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user) }
    let(:valid_params) { { document: { name: "Updated Document Name" } } }

    context "with valid parameters" do
      it "updates the document" do
        patch document_path(document), params: valid_params

        expect(document.reload.name).to eq("Updated Document Name")
      end

      it "redirects to documents index" do
        patch document_path(document), params: valid_params

        expect(response).to redirect_to(documents_path)
      end

      it "displays success message" do
        patch document_path(document), params: valid_params

        expect(flash[:notice]).to include("successfully")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { document: { name: "" } } }

      it "does not update the document" do
        original_name = document.name
        patch document_path(document), params: invalid_params

        expect(document.reload.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch document_path(document), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when document belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_document) { create(:document, :with_pdf, account: other_account, uploaded_by: other_user) }

      it "returns not found" do
        patch document_path(other_document), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /documents/:id" do
    let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user) }

    it "deletes the document" do
      expect {
        delete document_path(document)
      }.to change(Document, :count).by(-1)
    end

    it "redirects to documents index" do
      delete document_path(document)

      expect(response).to redirect_to(documents_path)
    end

    it "displays success message" do
      delete document_path(document)

      expect(flash[:notice]).to include("successfully")
    end

    context "when document belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_document) { create(:document, :with_pdf, account: other_account, uploaded_by: other_user) }

      it "returns not found" do
        delete document_path(other_document)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /documents/:id/download" do
    context "when document has file attached" do
      let!(:document) { create(:document, :with_pdf, account: account, uploaded_by: user) }

      it "redirects to the file download" do
        get download_document_path(document)

        expect(response).to have_http_status(:redirect)
      end
    end

    context "when document has no file attached" do
      let!(:document) { create(:document, account: account, uploaded_by: user) }

      it "redirects to documents index with alert" do
        get download_document_path(document)

        expect(response).to redirect_to(documents_path)
        expect(flash[:alert]).to include("not found")
      end
    end

    context "when document belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_document) { create(:document, :with_pdf, account: other_account, uploaded_by: other_user) }

      it "returns not found" do
        get download_document_path(other_document)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "document categories" do
    Document.categories.keys.each do |category|
      context "with #{category} category" do
        let!(:document) { create(:document, category.to_sym, :with_pdf, account: account, uploaded_by: user, name: "#{category.humanize} Test") }

        it "displays the document in the list" do
          get documents_path

          expect(response.body).to include("#{category.humanize} Test")
        end

        it "can filter by #{category} category" do
          get documents_path, params: { category: category }

          expect(response.body).to include("#{category.humanize} Test")
        end
      end
    end
  end
end
