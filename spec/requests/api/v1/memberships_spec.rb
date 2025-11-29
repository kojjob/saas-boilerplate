# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Memberships", type: :request do
  let!(:user) { create(:user, :confirmed, :owner) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{api_token.token}" } }
  let!(:account) { user.memberships.first.account }

  describe "GET /api/v1/accounts/:account_id/memberships" do
    let!(:other_member) { create(:membership, account: account) }

    context "with access to the account" do
      it "returns the account memberships" do
        get api_v1_account_memberships_path(account), headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]).to be_an(Array)
        expect(json["data"].length).to eq(2)
      end
    end

    context "without access to the account" do
      let(:other_account) { create(:account) }

      it "returns forbidden" do
        get api_v1_account_memberships_path(other_account), headers: auth_headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/accounts/:account_id/memberships" do
    let!(:new_user) { create(:user, :confirmed) }

    context "as account owner" do
      it "creates a new membership" do
        expect {
          post api_v1_account_memberships_path(account),
            params: { membership: { email: new_user.email, role: "member" } },
            headers: auth_headers,
            as: :json
        }.to change(Membership, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["user"]["id"]).to eq(new_user.id)
        expect(json["data"]["role"]).to eq("member")
      end

      it "returns not found for non-existent email" do
        post api_v1_account_memberships_path(account),
          params: { membership: { email: "nonexistent@example.com", role: "member" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "rejects invalid roles" do
        post api_v1_account_memberships_path(account),
          params: { membership: { email: new_user.email, role: "invalid_role" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "prevents duplicate memberships" do
        create(:membership, user: new_user, account: account)

        post api_v1_account_memberships_path(account),
          params: { membership: { email: new_user.email, role: "member" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as member (not owner)" do
      let(:member_user) { create(:user, :confirmed) }
      let(:member_membership) { create(:membership, user: member_user, account: account, role: "member") }
      let(:member_api_token) { create(:api_token, user: member_user) }
      let(:member_auth_headers) { { "Authorization" => "Bearer #{member_api_token.token}" } }

      it "returns forbidden" do
        member_membership # ensure membership exists
        post api_v1_account_memberships_path(account),
          params: { membership: { email: new_user.email, role: "member" } },
          headers: member_auth_headers,
          as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/accounts/:account_id/memberships/:id" do
    let!(:target_membership) { create(:membership, account: account, role: "member") }

    it "updates the membership role" do
      patch api_v1_account_membership_path(account, target_membership),
        params: { membership: { role: "admin" } },
        headers: auth_headers,
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["role"]).to eq("admin")
    end
  end

  describe "DELETE /api/v1/accounts/:account_id/memberships/:id" do
    let!(:target_membership) { create(:membership, account: account, role: "member") }

    it "removes the membership" do
      expect {
        delete api_v1_account_membership_path(account, target_membership),
          headers: auth_headers,
          as: :json
      }.to change(Membership, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
