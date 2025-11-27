# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_root_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when user is not an admin" do
      let(:user) { create(:user, :confirmed) }

      before { sign_in(user) }

      it "redirects with unauthorized message" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is an admin" do
      let(:admin) { create(:user, :confirmed, :admin) }

      before { sign_in(admin) }

      it "returns successful response" do
        get admin_root_path
        expect(response).to have_http_status(:ok)
      end

      it "displays dashboard statistics" do
        # Create some test data
        3.times { create(:user, :confirmed) }
        2.times { create(:account) }

        get admin_root_path
        expect(response.body).to include("Dashboard")
      end
    end
  end
end
