# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let!(:client) { create(:client, account: account) }

  before do
    sign_in(user)
  end

  describe "GET /projects" do
    let!(:projects) { create_list(:project, 3, account: account, client: client) }

    it "returns http success" do
      get projects_path

      expect(response).to have_http_status(:ok)
    end

    it "displays projects list" do
      get projects_path

      projects.each do |project|
        expect(response.body).to include(project.name)
      end
    end

    it "only shows projects from current account" do
      other_account = create(:account)
      other_client = create(:client, account: other_account)
      other_project = create(:project, account: other_account, client: other_client, name: "Other Account Project")

      get projects_path

      expect(response.body).not_to include("Other Account Project")
    end

    context "with search parameter" do
      let!(:searchable_project) { create(:project, account: account, client: client, name: "Searchable Project") }

      it "filters projects by search query" do
        get projects_path, params: { search: "Searchable" }

        expect(response.body).to include("Searchable Project")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get projects_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /projects/:id" do
    let!(:project) { create(:project, account: account, client: client) }

    it "returns http success" do
      get project_path(project)

      expect(response).to have_http_status(:ok)
    end

    it "displays project details" do
      get project_path(project)

      expect(response.body).to include(project.name)
      expect(response.body).to include(client.name)
    end

    context "when project belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }

      it "returns not found" do
        get project_path(other_project)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with time entries and material entries" do
      let!(:time_entries) { create_list(:time_entry, 2, project: project, account: account, user: user) }
      let!(:material_entries) { create_list(:material_entry, 2, project: project, account: account, user: user) }

      it "displays recent time entries" do
        get project_path(project)

        time_entries.each do |entry|
          expect(response.body).to include(entry.description)
        end
      end

      it "displays recent material entries" do
        get project_path(project)

        material_entries.each do |entry|
          expect(response.body).to include(entry.name)
        end
      end
    end
  end

  describe "GET /projects/new" do
    it "returns http success" do
      get new_project_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new project form" do
      get new_project_path

      expect(response.body).to include("Create new project")
    end

    context "with client_id parameter" do
      it "preselects the client" do
        get new_project_path, params: { client_id: client.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /projects" do
    let(:valid_params) do
      {
        project: {
          name: "New Project",
          client_id: client.id,
          description: "A test project",
          status: "draft",
          start_date: Date.today,
          budget: 5000.00
        }
      }
    end

    context "with valid parameters" do
      it "creates a new project" do
        expect {
          post projects_path, params: valid_params
        }.to change(Project, :count).by(1)
      end

      it "redirects to projects index" do
        post projects_path, params: valid_params

        expect(response).to redirect_to(projects_path)
      end

      it "displays success message" do
        post projects_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end

      it "associates project with current account" do
        post projects_path, params: valid_params

        expect(Project.last.account).to eq(account)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          project: {
            name: "",
            client_id: nil
          }
        }
      end

      it "does not create a new project" do
        expect {
          post projects_path, params: invalid_params
        }.not_to change(Project, :count)
      end

      it "returns unprocessable entity status" do
        post projects_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /projects/:id/edit" do
    let!(:project) { create(:project, account: account, client: client) }

    it "returns http success" do
      get edit_project_path(project)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with project data" do
      get edit_project_path(project)

      expect(response.body).to include("Edit project")
      expect(response.body).to include(project.name)
    end

    context "when project belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }

      it "returns not found" do
        get edit_project_path(other_project)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /projects/:id" do
    let!(:project) { create(:project, account: account, client: client) }
    let(:valid_params) { { project: { name: "Updated Project Name" } } }

    context "with valid parameters" do
      it "updates the project" do
        patch project_path(project), params: valid_params

        expect(project.reload.name).to eq("Updated Project Name")
      end

      it "redirects to projects index" do
        patch project_path(project), params: valid_params

        expect(response).to redirect_to(projects_path)
      end

      it "displays success message" do
        patch project_path(project), params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { project: { name: "" } } }

      it "does not update the project" do
        original_name = project.name
        patch project_path(project), params: invalid_params

        expect(project.reload.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch project_path(project), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when project belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }

      it "returns not found" do
        patch project_path(other_project), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /projects/:id" do
    let!(:project) { create(:project, account: account, client: client) }

    context "when project has no invoices" do
      it "deletes the project" do
        expect {
          delete project_path(project)
        }.to change(Project, :count).by(-1)
      end

      it "redirects to projects index" do
        delete project_path(project)

        expect(response).to redirect_to(projects_path)
      end

      it "displays success message" do
        delete project_path(project)

        expect(flash[:notice]).to include("successfully deleted")
      end
    end

    context "when project has invoices" do
      let!(:invoice) { create(:invoice, project: project, client: client, account: account) }

      it "does not delete the project" do
        expect {
          delete project_path(project)
        }.not_to change(Project, :count)
      end

      it "redirects to projects index with alert" do
        delete project_path(project)

        expect(response).to redirect_to(projects_path)
        expect(flash[:alert]).to include("Cannot delete")
      end
    end

    context "when project belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }

      it "returns not found" do
        delete project_path(other_project)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /projects/:id/archive" do
    let!(:project) { create(:project, :active, account: account, client: client) }

    it "archives the project" do
      patch archive_project_path(project)

      expect(project.reload.status).to eq("cancelled")
    end

    it "redirects to projects index" do
      patch archive_project_path(project)

      expect(response).to redirect_to(projects_path)
    end

    it "displays success message" do
      patch archive_project_path(project)

      expect(flash[:notice]).to include("archived")
    end

    context "when project belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }

      it "returns not found" do
        patch archive_project_path(other_project)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
