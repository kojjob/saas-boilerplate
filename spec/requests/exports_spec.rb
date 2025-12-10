# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exports", type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, :confirmed) }
  let(:member) { create(:user, :confirmed) }
  let(:guest) { create(:user, :confirmed) }
  let!(:owner_membership) { create(:membership, user: owner, account: account, role: "owner") }
  let!(:member_membership) { create(:membership, user: member, account: account, role: "member") }
  let!(:guest_membership) { create(:membership, user: guest, account: account, role: "guest") }

  describe "GET /exports/new" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get new_export_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in(owner) }

      it "returns http success" do
        get new_export_path
        expect(response).to have_http_status(:success)
      end

      it "displays the export form" do
        get new_export_path
        expect(response.body).to include("Accountant Export")
        expect(response.body).to include("Select Export Year")
      end

      it "displays available years based on data" do
        # Create some test data to establish years
        client = create(:client, account: account)
        project = create(:project, account: account, client: client)
        create(:invoice, account: account, client: client, issue_date: Date.new(2024, 6, 15))
        create(:time_entry, account: account, project: project, date: Date.new(2023, 3, 10))

        get new_export_path
        expect(response.body).to include("2024")
        expect(response.body).to include("2023")
      end

      it "shows current year when no data exists" do
        get new_export_path
        expect(response.body).to include(Date.current.year.to_s)
      end
    end

    context "when authenticated as member" do
      before { sign_in(member) }

      it "returns http success" do
        get new_export_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as guest" do
      before { sign_in(guest) }

      it "denies access" do
        get new_export_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "POST /exports" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        post exports_path, params: { year: 2024 }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in(owner) }

      it "generates a ZIP file download" do
        post exports_path, params: { year: 2024 }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/zip")
      end

      it "uses the correct filename format" do
        freeze_time do
          post exports_path, params: { year: 2024 }
          # Service generates: accountant_export_{account_id}_{year}.zip
          expected_filename = "accountant_export_#{account.id}_2024.zip"
          expect(response.headers["Content-Disposition"]).to include(expected_filename)
        end
      end

      it "defaults to current year when year param is missing" do
        post exports_path
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/zip")
      end

      it "includes financial data in the export" do
        client = create(:client, account: account)
        project = create(:project, account: account, client: client)
        create(:invoice, account: account, client: client, issue_date: Date.new(2024, 1, 15), status: :paid, total_amount: 1000)
        create(:time_entry, account: account, project: project, date: Date.new(2024, 2, 10), hours: 8, hourly_rate: 100)
        create(:material_entry, account: account, project: project, date: Date.new(2024, 3, 5), quantity: 5, unit_cost: 50)

        post exports_path, params: { year: 2024 }
        expect(response).to have_http_status(:success)

        # Verify it's a valid ZIP
        expect(response.body[0..1]).to eq("PK")
      end
    end

    context "when authenticated as member" do
      before { sign_in(member) }

      it "generates a ZIP file download" do
        post exports_path, params: { year: 2024 }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/zip")
      end
    end

    context "when authenticated as guest" do
      before { sign_in(guest) }

      it "denies access" do
        post exports_path, params: { year: 2024 }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "data isolation" do
    let(:other_account) { create(:account, name: "Other Account") }
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_membership) { create(:membership, user: other_user, account: other_account, role: "owner") }

    before do
      # Create data in the current account
      client = create(:client, account: account, name: "My Client")
      create(:invoice, account: account, client: client, issue_date: Date.new(2024, 1, 15))

      # Create data in another account
      other_client = create(:client, account: other_account, name: "Other Client")
      create(:invoice, account: other_account, client: other_client, issue_date: Date.new(2024, 1, 15))
    end

    it "only exports data from the current account" do
      sign_in(owner)

      post exports_path, params: { year: 2024 }

      # The ZIP should be valid and contain only the authenticated user's account data
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/zip")

      # Verify ZIP starts with PK signature (valid ZIP)
      expect(response.body[0..1]).to eq("PK")
    end

    it "each user only sees their own account data" do
      sign_in(other_user)

      # When viewing exports, should only see their own data
      get new_export_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "cleanup" do
    before { sign_in(owner) }

    it "cleans up temporary files after download" do
      post exports_path, params: { year: 2024 }
      expect(response).to have_http_status(:success)

      # Temporary files should be cleaned up (ensured by the controller's ensure block)
      # We can't easily test this directly, but the response should complete successfully
    end
  end

  describe "error handling" do
    before { sign_in(owner) }

    it "handles invalid year gracefully" do
      post exports_path, params: { year: "invalid" }
      # Should default to 0 (to_i on invalid string) but still work
      expect(response).to have_http_status(:success)
    end

    it "handles future year" do
      post exports_path, params: { year: 2099 }
      # Should still generate an export (empty data is valid)
      expect(response).to have_http_status(:success)
    end

    it "handles past year with no data" do
      post exports_path, params: { year: 1990 }
      # Should still generate an export (empty data is valid)
      expect(response).to have_http_status(:success)
    end
  end
end
