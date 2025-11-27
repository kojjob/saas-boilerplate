# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not signed in" do
      it "renders the landing page" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "displays the landing page content" do
        get root_path
        expect(response.body).to include("Sign in")
      end
    end

    context "when user is signed in" do
      let(:user) { create(:user) }
      let(:account) { create(:account) }

      before do
        create(:membership, user: user, account: account, role: "owner")
        sign_in(user, account: account)
      end

      it "redirects to dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
