# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Authentication", type: :request do
  describe "POST /api/v1/auth/token" do
    let(:user) { create(:user, :confirmed, :owner, password: "password123") }

    context "with valid credentials" do
      it "returns an API token" do
        post api_v1_auth_token_path, params: {
          email: user.email,
          password: "password123"
        }, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["token"]).to be_present
        expect(json["user"]["id"]).to eq(user.id)
        expect(json["user"]["email"]).to eq(user.email)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized error" do
        post api_v1_auth_token_path, params: {
          email: user.email,
          password: "wrongpassword"
        }, as: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end

    context "with missing parameters" do
      it "returns bad request error" do
        post api_v1_auth_token_path, params: {
          email: user.email
        }, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE /api/v1/auth/token" do
    let(:user) { create(:user, :confirmed) }
    let(:api_token) { create(:api_token, user: user) }

    context "with valid token" do
      it "revokes the token" do
        delete api_v1_auth_token_path,
          headers: { "Authorization" => "Bearer #{api_token.token}" },
          as: :json

        expect(response).to have_http_status(:no_content)
        expect(api_token.reload.revoked_at).to be_present
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete api_v1_auth_token_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
