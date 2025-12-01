# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Owner::Dashboard", type: :request do
  let(:free_plan) { create(:plan, name: "Free", price_cents: 0, interval: "month") }
  let(:pro_plan) { create(:plan, name: "Pro", price_cents: 4900, interval: "month") }

  describe "GET /owner" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get owner_root_path

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as a regular user (not site_admin)" do
      let(:user) { create(:user, site_admin: false) }
      let(:account) { create(:account, plan: pro_plan) }

      before do
        create(:membership, user: user, account: account, role: :member)
        sign_in(user)
      end

      it "redirects to dashboard with unauthorized message" do
        get owner_root_path

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("You don't have permission to access the Owner Portal.")
      end
    end

    context "when signed in as a site_admin" do
      let(:admin_user) { create(:user, site_admin: true) }
      let(:account) { create(:account, plan: pro_plan) }

      before do
        create(:membership, user: admin_user, account: account, role: :owner)
        sign_in(admin_user)
      end

      it "returns success" do
        get owner_root_path

        expect(response).to have_http_status(:ok)
      end

      it "displays the owner dashboard" do
        get owner_root_path

        expect(response.body).to include("Owner Dashboard")
      end

      it "displays MRR metrics" do
        # Create some accounts for MRR calculation
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)

        get owner_root_path

        expect(response.body).to include("MRR")
        expect(response.body).to include("ARR")
      end

      it "displays customer metrics" do
        create_list(:account, 5, subscription_status: "active", plan: pro_plan)
        create_list(:account, 2, subscription_status: "trialing", plan: pro_plan)

        get owner_root_path

        expect(response.body).to include("Total Customers")
        expect(response.body).to include("Active Customers")
      end

      it "displays payment health metrics" do
        create_list(:account, 2, subscription_status: "past_due", plan: pro_plan)

        get owner_root_path

        expect(response.body).to include("Past Due")
        expect(response.body).to include("At-Risk Revenue")
      end
    end
  end

  describe "GET /owner/metrics" do
    let(:admin_user) { create(:user, site_admin: true) }
    let(:account) { create(:account, plan: pro_plan) }

    before do
      create(:membership, user: admin_user, account: account, role: :owner)
      sign_in(admin_user)
    end

    context "requesting JSON format" do
      it "returns metrics data as JSON" do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)

        get owner_metrics_path, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key("mrr")
        expect(json_response).to have_key("arr")
        expect(json_response).to have_key("total_customers")
        expect(json_response).to have_key("active_customers")
      end
    end
  end
end
