# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Notifications", type: :request do
  let!(:user) { create(:user, :confirmed, :owner) }
  let!(:api_token) { create(:api_token, user: user) }
  let(:auth_headers) { { "Authorization" => "Bearer #{api_token.token}" } }

  describe "GET /api/v1/notifications" do
    let!(:notification1) { create(:notification, user: user, title: "First notification") }
    let!(:notification2) { create(:notification, user: user, title: "Second notification", read_at: Time.current) }
    let!(:other_notification) { create(:notification, title: "Other user notification") }

    it "returns the user's notifications" do
      get api_v1_notifications_path, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["notifications"].length).to eq(2)
    end

    it "can filter to only unread notifications" do
      get api_v1_notifications_path(unread: "true"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["notifications"].length).to eq(1)
      expect(json["data"]["notifications"].first["title"]).to eq("First notification")
    end

    context "without authentication" do
      it "returns unauthorized" do
        get api_v1_notifications_path, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/notifications/:id" do
    let!(:notification) { create(:notification, user: user, title: "Test notification") }

    it "returns the notification" do
      get api_v1_notification_path(notification), headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["notification"]["id"]).to eq(notification.id)
      expect(json["data"]["notification"]["title"]).to eq("Test notification")
    end

    context "when notification belongs to another user" do
      let!(:other_notification) { create(:notification) }

      it "returns not found" do
        get api_v1_notification_path(other_notification), headers: auth_headers, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/notifications/:id/mark_as_read" do
    let!(:notification) { create(:notification, user: user, read_at: nil) }

    it "marks the notification as read" do
      expect {
        post mark_as_read_api_v1_notification_path(notification), headers: auth_headers, as: :json
      }.to change { notification.reload.read_at }.from(nil)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/notifications/mark_all_as_read" do
    let!(:notification1) { create(:notification, user: user, read_at: nil) }
    let!(:notification2) { create(:notification, user: user, read_at: nil) }
    let!(:other_notification) { create(:notification, read_at: nil) }

    it "marks all user notifications as read" do
      post mark_all_as_read_api_v1_notifications_path, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(notification1.reload.read_at).to be_present
      expect(notification2.reload.read_at).to be_present
      expect(other_notification.reload.read_at).to be_nil
    end
  end

  describe "GET /api/v1/notifications/unread_count" do
    let!(:unread_notification1) { create(:notification, user: user, read_at: nil) }
    let!(:unread_notification2) { create(:notification, user: user, read_at: nil) }
    let!(:read_notification) { create(:notification, user: user, read_at: Time.current) }

    it "returns the unread notification count" do
      get unread_count_api_v1_notifications_path, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["unread_count"]).to eq(2)
    end
  end

  describe "DELETE /api/v1/notifications/:id" do
    let!(:notification) { create(:notification, user: user) }

    it "deletes the notification" do
      expect {
        delete api_v1_notification_path(notification), headers: auth_headers, as: :json
      }.to change(Notification, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    context "when notification belongs to another user" do
      let!(:other_notification) { create(:notification) }

      it "returns not found" do
        delete api_v1_notification_path(other_notification), headers: auth_headers, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
