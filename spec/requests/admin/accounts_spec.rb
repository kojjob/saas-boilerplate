# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Accounts", type: :request do
  let(:admin) { create(:user, :confirmed, :admin) }
  let!(:account) { create(:account, name: "Test Company") }

  before { sign_in(admin) }

  describe "GET /admin/accounts" do
    it "returns successful response" do
      get admin_accounts_path
      expect(response).to have_http_status(:ok)
    end

    it "lists all accounts" do
      get admin_accounts_path
      expect(response.body).to include(account.name)
    end

    it "supports filtering by subscription status" do
      get admin_accounts_path, params: { status: "trialing" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/accounts/:id" do
    it "shows account details" do
      get admin_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.name)
    end
  end

  describe "GET /admin/accounts/:id/edit" do
    it "renders edit form" do
      get edit_admin_account_path(account)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/accounts/:id" do
    context "with valid params" do
      it "updates the account" do
        patch admin_account_path(account), params: { account: { name: "Updated Company" } }
        expect(response).to redirect_to(admin_account_path(account))
        account.reload
        expect(account.name).to eq("Updated Company")
      end
    end

    context "with invalid params" do
      it "renders edit form with errors" do
        patch admin_account_path(account), params: { account: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/accounts/:id" do
    it "soft deletes the account" do
      delete admin_account_path(account)
      expect(response).to redirect_to(admin_accounts_path)
      expect(account.reload.discarded?).to be true
    end
  end

  describe "POST /admin/accounts/:id/upgrade" do
    let!(:pro_plan) { create(:plan, :pro) }

    it "upgrades account to specified plan" do
      post upgrade_admin_account_path(account), params: { plan_id: pro_plan.id }
      expect(response).to redirect_to(admin_account_path(account))
      account.reload
      expect(account.plan).to eq(pro_plan)
    end
  end

  describe "POST /admin/accounts/:id/extend_trial" do
    it "extends the trial period" do
      original_trial = account.trial_ends_at
      post extend_trial_admin_account_path(account), params: { days: 14 }
      expect(response).to redirect_to(admin_account_path(account))
      account.reload
      expect(account.trial_ends_at).to be > original_trial
    end
  end
end
