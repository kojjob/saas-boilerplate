# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MaterialEntries", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }
  let!(:client) { create(:client, account: account) }
  let!(:project) { create(:project, account: account, client: client) }

  before do
    sign_in(user)
  end

  describe "GET /material_entries" do
    let!(:material_entries) { create_list(:material_entry, 3, account: account, project: project, user: user) }

    it "returns http success" do
      get material_entries_path

      expect(response).to have_http_status(:ok)
    end

    it "displays material entries list" do
      get material_entries_path

      material_entries.each do |entry|
        expect(response.body).to include(entry.name)
      end
    end

    it "only shows material entries from current account" do
      other_account = create(:account)
      other_user = create(:user, :confirmed)
      other_client = create(:client, account: other_account)
      other_project = create(:project, account: other_account, client: other_client)
      other_entry = create(:material_entry, account: other_account, project: other_project, user: other_user, name: "Other Account Material")

      get material_entries_path

      expect(response.body).not_to include("Other Account Material")
    end

    context "with project filter" do
      let!(:project2) { create(:project, account: account, client: client, name: "Second Project") }
      let!(:project_entry) { create(:material_entry, account: account, project: project, user: user, name: "Project One Material") }
      let!(:project2_entry) { create(:material_entry, account: account, project: project2, user: user, name: "Project Two Material") }

      it "filters material entries by project" do
        get material_entries_path, params: { project_id: project.id }

        expect(response.body).to include("Project One Material")
        expect(response.body).not_to include("Project Two Material")
      end
    end

    context "with period filter" do
      let!(:this_week_entry) { create(:material_entry, :this_week, account: account, project: project, user: user, name: "This Week Material") }
      let!(:last_month_entry) { create(:material_entry, :last_month, account: account, project: project, user: user, name: "Last Month Material") }

      it "filters material entries by this_week" do
        get material_entries_path, params: { period: "this_week" }

        expect(response.body).to include("This Week Material")
      end

      it "filters material entries by this_month" do
        get material_entries_path, params: { period: "this_month" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with billable filter" do
      let!(:billable_entry) { create(:material_entry, account: account, project: project, user: user, billable: true, name: "Billable Material") }
      let!(:non_billable_entry) { create(:material_entry, :non_billable, account: account, project: project, user: user, name: "Non Billable Material") }

      it "filters by billable=true" do
        get material_entries_path, params: { billable: "true" }

        expect(response.body).to include("Billable Material")
        expect(response.body).not_to include("Non Billable Material")
      end

      it "filters by billable=false" do
        get material_entries_path, params: { billable: "false" }

        expect(response.body).to include("Non Billable Material")
      end
    end

    context "with invoiced filter" do
      let!(:invoiced_entry) { create(:material_entry, :invoiced, account: account, project: project, user: user, name: "Invoiced Material") }
      let!(:not_invoiced_entry) { create(:material_entry, account: account, project: project, user: user, invoiced: false, name: "Not Invoiced Material") }

      it "filters by invoiced=true" do
        get material_entries_path, params: { invoiced: "true" }

        expect(response.body).to include("Invoiced Material")
        expect(response.body).not_to include("Not Invoiced Material")
      end

      it "filters by invoiced=false" do
        get material_entries_path, params: { invoiced: "false" }

        expect(response.body).to include("Not Invoiced Material")
      end
    end

    context "when user is not authenticated" do
      before { sign_out }

      it "redirects to sign in" do
        get material_entries_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /material_entries/:id" do
    let!(:material_entry) { create(:material_entry, account: account, project: project, user: user) }

    it "returns http success" do
      get material_entry_path(material_entry)

      expect(response).to have_http_status(:ok)
    end

    it "displays material entry details" do
      get material_entry_path(material_entry)

      expect(response.body).to include(material_entry.name)
      expect(response.body).to include(project.name)
    end

    context "when material entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        get material_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /material_entries/new" do
    it "returns http success" do
      get new_material_entry_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the new material entry form" do
      get new_material_entry_path

      expect(response.body).to include("Add material")
    end

    context "with project_id parameter" do
      it "preselects the project" do
        get new_material_entry_path, params: { project_id: project.id }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /material_entries" do
    let(:valid_params) do
      {
        material_entry: {
          project_id: project.id,
          date: Date.current,
          name: "Copper Pipes",
          description: "2 inch copper pipes for main line",
          quantity: 10,
          unit: "feet",
          unit_cost: 15.00,
          billable: true,
          markup_percentage: 20.0
        }
      }
    end

    context "with valid parameters" do
      it "creates a new material entry" do
        expect {
          post material_entries_path, params: valid_params
        }.to change(MaterialEntry, :count).by(1)
      end

      it "redirects to material entries index" do
        post material_entries_path, params: valid_params

        expect(response).to redirect_to(material_entries_path)
      end

      it "displays success message" do
        post material_entries_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end

      it "associates material entry with current account" do
        post material_entries_path, params: valid_params

        expect(MaterialEntry.last.account).to eq(account)
      end

      it "associates material entry with current user" do
        post material_entries_path, params: valid_params

        expect(MaterialEntry.last.user).to eq(user)
      end

      it "calculates total_amount with markup for billable entries" do
        post material_entries_path, params: valid_params

        entry = MaterialEntry.last
        expected_subtotal = 10 * 15.00  # 150.00
        expected_markup = expected_subtotal * 0.20  # 30.00
        expect(entry.total_amount).to eq(expected_subtotal + expected_markup)  # 180.00
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          material_entry: {
            project_id: project.id,
            date: nil,
            name: "",
            quantity: nil,
            unit_cost: nil
          }
        }
      end

      it "does not create a new material entry" do
        expect {
          post material_entries_path, params: invalid_params
        }.not_to change(MaterialEntry, :count)
      end

      it "returns unprocessable entity status" do
        post material_entries_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with zero quantity" do
      let(:invalid_params) do
        {
          material_entry: {
            project_id: project.id,
            date: Date.current,
            name: "Test Material",
            quantity: 0,
            unit_cost: 10.00
          }
        }
      end

      it "does not create a new material entry" do
        expect {
          post material_entries_path, params: invalid_params
        }.not_to change(MaterialEntry, :count)
      end
    end
  end

  describe "GET /material_entries/:id/edit" do
    let!(:material_entry) { create(:material_entry, account: account, project: project, user: user) }

    it "returns http success" do
      get edit_material_entry_path(material_entry)

      expect(response).to have_http_status(:ok)
    end

    it "displays the edit form with material entry data" do
      get edit_material_entry_path(material_entry)

      expect(response.body).to include("Edit material")
      expect(response.body).to include(material_entry.name)
    end

    context "when material entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        get edit_material_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /material_entries/:id" do
    let!(:material_entry) { create(:material_entry, account: account, project: project, user: user, quantity: 5) }
    let(:valid_params) { { material_entry: { quantity: 10, name: "Updated Material" } } }

    context "with valid parameters" do
      it "updates the material entry" do
        patch material_entry_path(material_entry), params: valid_params

        expect(material_entry.reload.quantity).to eq(10)
        expect(material_entry.name).to eq("Updated Material")
      end

      it "redirects to material entries index" do
        patch material_entry_path(material_entry), params: valid_params

        expect(response).to redirect_to(material_entries_path)
      end

      it "displays success message" do
        patch material_entry_path(material_entry), params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { material_entry: { quantity: 0 } } }

      it "does not update the material entry" do
        original_quantity = material_entry.quantity
        patch material_entry_path(material_entry), params: invalid_params

        expect(material_entry.reload.quantity).to eq(original_quantity)
      end

      it "returns unprocessable entity status" do
        patch material_entry_path(material_entry), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when material entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        patch material_entry_path(other_entry), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /material_entries/:id" do
    let!(:material_entry) { create(:material_entry, account: account, project: project, user: user) }

    it "deletes the material entry" do
      expect {
        delete material_entry_path(material_entry)
      }.to change(MaterialEntry, :count).by(-1)
    end

    it "redirects to material entries index" do
      delete material_entry_path(material_entry)

      expect(response).to redirect_to(material_entries_path)
    end

    it "displays success message" do
      delete material_entry_path(material_entry)

      expect(flash[:notice]).to include("successfully deleted")
    end

    context "when material entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        delete material_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /material_entries/:id/mark_invoiced" do
    let!(:material_entry) { create(:material_entry, account: account, project: project, user: user, invoiced: false) }

    it "marks the material entry as invoiced" do
      patch mark_invoiced_material_entry_path(material_entry)

      expect(material_entry.reload.invoiced).to be true
    end

    it "redirects to material entries index" do
      patch mark_invoiced_material_entry_path(material_entry)

      expect(response).to redirect_to(material_entries_path)
    end

    it "displays success message" do
      patch mark_invoiced_material_entry_path(material_entry)

      expect(flash[:notice]).to include("invoiced")
    end

    context "when material entry belongs to another account" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let(:other_entry) { create(:material_entry, account: other_account, project: other_project, user: other_user) }

      it "returns not found" do
        patch mark_invoiced_material_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /material_entries/report" do
    let!(:material_entries) { create_list(:material_entry, 3, :this_month, account: account, project: project, user: user) }

    it "returns http success" do
      get report_material_entries_path

      expect(response).to have_http_status(:ok)
    end

    it "displays material entries in the report" do
      get report_material_entries_path

      material_entries.each do |entry|
        expect(response.body).to include(entry.name)
      end
    end

    context "with date range parameters" do
      let(:start_date) { Date.current.beginning_of_month }
      let(:end_date) { Date.current.end_of_month }

      it "filters by date range" do
        get report_material_entries_path, params: { start_date: start_date, end_date: end_date }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when start_date is after end_date" do
      it "swaps the dates automatically" do
        get report_material_entries_path, params: {
          start_date: Date.current.end_of_month,
          end_date: Date.current.beginning_of_month
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with multiple projects in report" do
      let!(:project2) { create(:project, account: account, client: client, name: "Second Project") }
      let!(:project_entries) do
        [
          create(:material_entry, :this_month, account: account, project: project, user: user, name: "Project 1 Material"),
          create(:material_entry, :this_month, account: account, project: project2, user: user, name: "Project 2 Material")
        ]
      end

      it "displays project names in the report without N+1 queries" do
        get report_material_entries_path

        expect(response.body).to include(project.name)
        expect(response.body).to include(project2.name)
      end

      it "shows project breakdown with amounts" do
        get report_material_entries_path

        expect(response.body).to include("Materials by Project")
        expect(response.body).to include(project.name)
      end
    end

    context "with only current account data" do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, :confirmed) }
      let(:other_client) { create(:client, account: other_account) }
      let(:other_project) { create(:project, account: other_account, client: other_client) }
      let!(:other_entry) { create(:material_entry, :this_month, account: other_account, project: other_project, user: other_user, name: "Other Account Material") }

      it "does not include material entries from other accounts" do
        get report_material_entries_path

        expect(response.body).not_to include("Other Account Material")
      end
    end
  end

  describe "billable vs non-billable entries" do
    context "with billable entry" do
      let!(:billable_entry) { create(:material_entry, account: account, project: project, user: user, quantity: 5, unit_cost: 20.0, markup_percentage: 25.0, billable: true) }

      it "calculates total_amount with markup" do
        subtotal = 5 * 20.0  # 100.00
        markup = subtotal * 0.25  # 25.00
        expect(billable_entry.total_amount).to eq(subtotal + markup)  # 125.00
      end
    end

    context "with non-billable entry" do
      let!(:non_billable_entry) { create(:material_entry, :non_billable, account: account, project: project, user: user) }

      it "has zero or nil total_amount" do
        expect(non_billable_entry.total_amount).to eq(0).or be_nil
      end
    end
  end

  describe "markup calculations" do
    context "with no markup" do
      let!(:entry) { create(:material_entry, :no_markup, account: account, project: project, user: user, quantity: 10, unit_cost: 10.0) }

      it "calculates total_amount equal to subtotal" do
        expect(entry.total_amount).to eq(100.0)
      end
    end

    context "with high markup" do
      let!(:entry) { create(:material_entry, :high_markup, account: account, project: project, user: user, quantity: 10, unit_cost: 10.0) }

      it "calculates total_amount with 50% markup" do
        subtotal = 100.0
        markup = 50.0  # 50% of 100
        expect(entry.total_amount).to eq(subtotal + markup)
      end
    end
  end
end
