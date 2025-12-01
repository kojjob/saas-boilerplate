# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TimeEntries", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let!(:client) { create(:client, account: account) }
  let!(:project) { create(:project, account: account, client: client) }

  before do
    sign_in(user)
  end

  describe "GET /time_entries" do
    let!(:time_entries) { create_list(:time_entry, 3, account: account, project: project, user: user) }

    it "returns http success" do
      get time_entries_path

      expect(response).to have_http_status(:ok)
    end

    it "displays time entries list" do
      get time_entries_path

      time_entries.each do |entry|
        expect(response.body).to include(entry.description)
      end
    end

    it "only shows time entries from current account" do
      other_account = create(:account)
      other_user = create(:user, :confirmed)
      other_client = create(:client, account: other_account)
      other_project = create(:project, account: other_account, client: other_client)
      other_entry = create(:time_entry, account: other_account, project: other_project, user: other_user, description: "Other Account Entry")

      get time_entries_path

      expect(response.body).not_to include("Other Account Entry")
    end

    context "with project filter" do
      let!(:project2) { create(:project, account: account, client: client, name: "Second Project") }
      let!(:project_entry) { create(:time_entry, account: account, project: project, user: user, description: "Project One Entry") }
      let!(:project2_entry) { create(:time_entry, account: account, project: project2, user: user, description: "Project Two Entry") }

      it "filters time entries by project" do
        get time_entries_path, params: { project_id: project.id }

        expect(response.body).to include("Project One Entry")
        expect(response.body).not_to include("Project Two Entry")
      end
    end

    context "with period filter" do
      let!(:this_week_entry) { create(:time_entry, :this_week, account: account, project: project, user: user, description: "This Week Entry") }
      let!(:last_month_entry) { create(:time_entry, :last_month, account: account, project: project, user: user, description: "Last Month Entry") }

      it "filters time entries by this_week" do
        get time_entries_path, params: { period: "this_week" }

        expect(response.body).to include("This Week Entry")
      end

      it "filters time entries by this_month" do
        get time_entries_path, params: { period: "this_month" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with billable filter" do
      let!(:billable_entry) { create(:time_entry, :billable, account: account, project: project, user: user, description: "Billable Entry") }
      let!(:non_billable_entry) { create(:time_entry, :non_billable, account: account, project: project, user: user, description: "Non Billable Entry") }

      it "filters by billable=true" do
        get time_entries_path, params: { billable: "true" }

        expect(response.body).to include("Billable Entry")
        expect(response.body).not_to include("Non Billable Entry")
      end

      it "filters by billable=false" do
        get time_entries_path, params: { billable: "false" }

        expect(response.body).to include("Non Billable Entry")
      end
    end

    context "with invoiced filter" do
      let!(:invoiced_entry) { create(:time_entry, :invoiced, account: account, project: project, user: user, description: "Invoiced Entry") }
      let!(:not_invoiced_entry) { create(:time_entry, account: account, project: project, user: user, invoiced: false, description: "Not Invoiced Entry") }

      it "filters by invoiced=true" do
        get time_entries_path, params: { invoiced: "true" }

        expect(response.body).to include("Invoiced Entry")
        expect(response.body).not_to include("Not Invoiced Entry")
      end

      it "filters by invoiced=false" do
        get time_entries_path, params: { invoiced: "false" }

        expect(response.body).to include("Not Invoiced Entry")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get time_entries_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /time_entries/:id" do
    let!(:time_entry) { create(:time_entry, account: account, project: project, user: user) }

    it "returns http success" do
      get time_entry_path(time_entry)

      expect(response).to have_http_status(:ok)
    end

    it "displays time entry details" do
      get time_entry_path(time_entry)

      expect(response.body).to include(time_entry.description)
      expect(response.body).to include(project.name)
    end

    context "when time entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        get time_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /time_entries/new" do
    it "returns http success" do
      get new_time_entry_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new time entry form" do
      get new_time_entry_path

      expect(response.body).to include("Log time")
    end

    context "with project_id parameter" do
      it "preselects the project" do
        get new_time_entry_path, params: { project_id: project.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /time_entries" do
    let(:valid_params) do
      {
        time_entry: {
          project_id: project.id,
          date: Date.current,
          hours: 4.5,
          description: "Working on feature implementation",
          billable: true,
          hourly_rate: 75.00
        }
      }
    end

    context "with valid parameters" do
      it "creates a new time entry" do
        expect {
          post time_entries_path, params: valid_params
        }.to change(TimeEntry, :count).by(1)
      end

      it "redirects to time entries index" do
        post time_entries_path, params: valid_params

        expect(response).to redirect_to(time_entries_path)
      end

      it "displays success message" do
        post time_entries_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end

      it "associates time entry with current account" do
        post time_entries_path, params: valid_params

        expect(TimeEntry.last.account).to eq(account)
      end

      it "associates time entry with current user" do
        post time_entries_path, params: valid_params

        expect(TimeEntry.last.user).to eq(user)
      end

      it "calculates total_amount for billable entries" do
        post time_entries_path, params: valid_params

        expect(TimeEntry.last.total_amount).to eq(4.5 * 75.00)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          time_entry: {
            project_id: project.id,
            date: nil,
            hours: nil
          }
        }
      end

      it "does not create a new time entry" do
        expect {
          post time_entries_path, params: invalid_params
        }.not_to change(TimeEntry, :count)
      end

      it "returns unprocessable entity status" do
        post time_entries_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with hours exceeding 24" do
      let(:invalid_params) do
        {
          time_entry: {
            project_id: project.id,
            date: Date.current,
            hours: 25
          }
        }
      end

      it "does not create a new time entry" do
        expect {
          post time_entries_path, params: invalid_params
        }.not_to change(TimeEntry, :count)
      end
    end
  end

  describe "GET /time_entries/:id/edit" do
    let!(:time_entry) { create(:time_entry, account: account, project: project, user: user) }

    it "returns http success" do
      get edit_time_entry_path(time_entry)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with time entry data" do
      get edit_time_entry_path(time_entry)

      expect(response.body).to include("Edit time entry")
      expect(response.body).to include(time_entry.description)
    end

    context "when time entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        get edit_time_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /time_entries/:id" do
    let!(:time_entry) { create(:time_entry, account: account, project: project, user: user, hours: 4.0) }
    let(:valid_params) { { time_entry: { hours: 6.0, description: "Updated description" } } }

    context "with valid parameters" do
      it "updates the time entry" do
        patch time_entry_path(time_entry), params: valid_params

        expect(time_entry.reload.hours).to eq(6.0)
        expect(time_entry.description).to eq("Updated description")
      end

      it "redirects to time entries index" do
        patch time_entry_path(time_entry), params: valid_params

        expect(response).to redirect_to(time_entries_path)
      end

      it "displays success message" do
        patch time_entry_path(time_entry), params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { time_entry: { hours: 0 } } }

      it "does not update the time entry" do
        original_hours = time_entry.hours
        patch time_entry_path(time_entry), params: invalid_params

        expect(time_entry.reload.hours).to eq(original_hours)
      end

      it "returns unprocessable entity status" do
        patch time_entry_path(time_entry), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when time entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        patch time_entry_path(other_entry), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /time_entries/:id" do
    let!(:time_entry) { create(:time_entry, account: account, project: project, user: user) }

    it "deletes the time entry" do
      expect {
        delete time_entry_path(time_entry)
      }.to change(TimeEntry, :count).by(-1)
    end

    it "redirects to time entries index" do
      delete time_entry_path(time_entry)

      expect(response).to redirect_to(time_entries_path)
    end

    it "displays success message" do
      delete time_entry_path(time_entry)

      expect(flash[:notice]).to include("successfully deleted")
    end

    context "when time entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        delete time_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /time_entries/:id/mark_invoiced" do
    let!(:time_entry) { create(:time_entry, account: account, project: project, user: user, invoiced: false) }

    it "marks the time entry as invoiced" do
      patch mark_invoiced_time_entry_path(time_entry)

      expect(time_entry.reload.invoiced).to be true
    end

    it "redirects to time entries index" do
      patch mark_invoiced_time_entry_path(time_entry)

      expect(response).to redirect_to(time_entries_path)
    end

    it "displays success message" do
      patch mark_invoiced_time_entry_path(time_entry)

      expect(flash[:notice]).to include("invoiced")
    end

    context "when time entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:time_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        patch mark_invoiced_time_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /time_entries/report" do
    let!(:time_entries) { create_list(:time_entry, 3, :this_month, account: account, project: project, user: user) }

    it "returns http success" do
      get report_time_entries_path

      expect(response).to have_http_status(:ok)
    end

    it "displays time entries in the report" do
      get report_time_entries_path

      time_entries.each do |entry|
        expect(response.body).to include(entry.description)
      end
    end

    context "with date range parameters" do
      let(:start_date) { Date.current.beginning_of_month }
      let(:end_date) { Date.current.end_of_month }

      it "filters by date range" do
        get report_time_entries_path, params: { start_date: start_date, end_date: end_date }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "billable vs non-billable entries" do
    context "with billable entry" do
      let!(:billable_entry) { create(:time_entry, :billable, account: account, project: project, user: user, hours: 2.0, hourly_rate: 50.0) }

      it "calculates total_amount" do
        expect(billable_entry.total_amount).to eq(100.0)
      end
    end

    context "with non-billable entry" do
      let!(:non_billable_entry) { create(:time_entry, :non_billable, account: account, project: project, user: user) }

      it "has nil total_amount" do
        expect(non_billable_entry.total_amount).to be_nil
      end
    end
  end
end
