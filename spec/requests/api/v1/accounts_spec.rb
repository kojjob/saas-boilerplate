# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Accounts", type: :request do
  let(:user) { create(:user, :confirmed, :owner) }
  let(:api_token) { create(:api_token, user: user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{api_token.token}" } }
  let(:account) { user.memberships.first.account }

  describe "GET /api/v1/accounts" do
    it "returns the user's accounts" do
      get api_v1_accounts_path, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]).to be_an(Array)
      expect(json["data"].first["id"]).to eq(account.id)
    end

    context "without authentication" do
      it "returns unauthorized" do
        get api_v1_accounts_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/accounts/:id" do
    context "with access to the account" do
      it "returns the account details" do
        get api_v1_account_path(account), headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["id"]).to eq(account.id)
        expect(json["data"]["name"]).to eq(account.name)
        expect(json["data"]["subscription_status"]).to eq(account.subscription_status)
      end
    end

    context "without access to the account" do
      let(:other_account) { create(:account) }

      it "returns forbidden" do
        get api_v1_account_path(other_account), headers: auth_headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/accounts/:id" do
    context "as account owner" do
      it "updates the account" do
        patch api_v1_account_path(account),
          params: { account: { name: "Updated Name" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["name"]).to eq("Updated Name")
      end
    end

    context "as member (not owner)" do
      let(:member_user) { create(:user, :confirmed) }
      let(:member_membership) { create(:membership, user: member_user, account: account, role: "member") }
      let(:member_api_token) { create(:api_token, user: member_user) }
      let(:member_auth_headers) { { "Authorization" => "Bearer #{member_api_token.token}" } }

      it "returns forbidden" do
        member_membership # ensure membership exists
        patch api_v1_account_path(account),
          params: { account: { name: "Updated Name" } },
          headers: member_auth_headers,
          as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
