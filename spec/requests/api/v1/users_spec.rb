# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Users", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{api_token.token}" } }

  describe "GET /api/v1/users/me" do
    context "with valid authentication" do
      it "returns the current user" do
        get api_v1_users_me_path, headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["id"]).to eq(user.id)
        expect(json["data"]["email"]).to eq(user.email)
        expect(json["data"]["first_name"]).to eq(user.first_name)
        expect(json["data"]["last_name"]).to eq(user.last_name)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get api_v1_users_me_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with revoked token" do
      before { api_token.revoke! }

      it "returns unauthorized" do
        get api_v1_users_me_path, headers: auth_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/users/me" do
    context "with valid parameters" do
      it "updates the current user" do
        patch api_v1_users_me_path,
          params: { user: { first_name: "UpdatedName" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["first_name"]).to eq("UpdatedName")
        expect(user.reload.first_name).to eq("UpdatedName")
      end
    end

    context "with invalid parameters" do
      it "returns validation errors" do
        patch api_v1_users_me_path,
          params: { user: { email: "" } },
          headers: auth_headers,
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end
end
