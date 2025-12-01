# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accounts", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }

  before do
    sign_in(user)
  end

  describe "GET /account" do
    it "returns http success" do
      get account_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the account information" do
      get account_path

      expect(response.body).to include(account.name)
    end

    context "when user has no account" do
      let(:user_without_account) { create(:user, :confirmed) }

      before do
        sign_out
        sign_in(user_without_account)
      end

      it "redirects to root path" do
        get account_path

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /account/edit" do
    context "when user is owner" do
      it "returns http success" do
        get edit_account_path

        expect(response).to have_http_status(:ok)
      end

      it "displays the edit form" do
        get edit_account_path

        expect(response.body).to include("Edit Account")
        expect(response.body).to include(account.name)
      end
    end

    context "when user is admin" do
      let(:admin_user) { create(:user, :confirmed) }
      let!(:admin_membership) { create(:membership, user: admin_user, account: account, role: "admin") }

      before do
        sign_out
        sign_in(admin_user)
      end

      it "returns http success" do
        get edit_account_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is member" do
      let(:member_user) { create(:user, :confirmed) }
      let!(:member_membership) { create(:membership, user: member_user, account: account, role: "member") }

      before do
        sign_out
        sign_in(member_user)
      end

      it "redirects to account show page" do
        get edit_account_path

        expect(response).to redirect_to(account_path)
      end

      it "displays permission error" do
        get edit_account_path

        expect(flash[:alert]).to include("permission")
      end
    end
  end

  describe "PATCH /account" do
    let(:valid_params) { { account: { name: "New Account Name" } } }

    context "when user is owner" do
      it "updates the account" do
        patch account_path, params: valid_params

        expect(account.reload.name).to eq("New Account Name")
      end

      it "redirects to account show page" do
        patch account_path, params: valid_params

        expect(response).to redirect_to(account_path)
      end

      it "displays success message" do
        patch account_path, params: valid_params

        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "when user is admin" do
      let(:admin_user) { create(:user, :confirmed) }
      let!(:admin_membership) { create(:membership, user: admin_user, account: account, role: "admin") }

      before do
        sign_out
        sign_in(admin_user)
      end

      it "updates the account" do
        patch account_path, params: valid_params

        expect(account.reload.name).to eq("New Account Name")
      end
    end

    context "when user is member" do
      let(:member_user) { create(:user, :confirmed) }
      let!(:member_membership) { create(:membership, user: member_user, account: account, role: "member") }

      before do
        sign_out
        sign_in(member_user)
      end

      it "does not update the account" do
        original_name = account.name
        patch account_path, params: valid_params

        expect(account.reload.name).to eq(original_name)
      end

      it "redirects to account show page" do
        patch account_path, params: valid_params

        expect(response).to redirect_to(account_path)
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { account: { name: "" } } }

      it "does not update the account" do
        patch account_path, params: invalid_params

        expect(account.reload.name).not_to be_empty
      end

      it "re-renders the edit form" do
        patch account_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when updating subdomain" do
      let(:subdomain_params) { { account: { subdomain: "newsubdomain" } } }

      it "updates the subdomain" do
        patch account_path, params: subdomain_params

        expect(account.reload.subdomain).to eq("newsubdomain")
      end

      context "with reserved subdomain" do
        let(:invalid_subdomain_params) { { account: { subdomain: "admin" } } }

        it "does not update to reserved subdomain" do
          patch account_path, params: invalid_subdomain_params

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "POST /account/switch" do
    let(:other_account) { create(:account) }
    let!(:other_membership) { create(:membership, user: user, account: other_account, role: "member") }

    it "switches to the specified account" do
      post switch_account_path(account_id: other_account.id)

      expect(session[:current_account_id]).to eq(other_account.id)
    end

    it "redirects to dashboard" do
      post switch_account_path(account_id: other_account.id)

      expect(response).to redirect_to(dashboard_path)
    end

    it "displays success message" do
      post switch_account_path(account_id: other_account.id)

      expect(flash[:notice]).to include("Switched to")
    end

    context "when user does not have access to account" do
      let(:inaccessible_account) { create(:account) }

      it "does not switch accounts" do
        post switch_account_path(account_id: inaccessible_account.id)

        expect(session[:current_account_id]).not_to eq(inaccessible_account.id)
      end

      it "displays error message" do
        post switch_account_path(account_id: inaccessible_account.id)

        expect(flash[:alert]).to include("don't have access")
      end

      it "redirects to account show page" do
        post switch_account_path(account_id: inaccessible_account.id)

        expect(response).to redirect_to(account_path)
      end
    end
  end

  describe "GET /account/billing" do
    let!(:plans) { create_list(:plan, 3, active: true) }

    it "returns http success" do
      get billing_account_path

      expect(response).to have_http_status(:ok)
    end

    it "displays available plans" do
      get billing_account_path

      plans.each do |plan|
        expect(response.body).to include(plan.name)
      end
    end
  end
end
