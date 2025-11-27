# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user, :confirmed, :owner) }

  before do
    sign_in user
  end

  describe "GET /notifications" do
    let!(:notification1) { create(:notification, user: user, title: "First notification") }
    let!(:notification2) { create(:notification, user: user, title: "Second notification") }

    it "returns a success response" do
      get notifications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("First notification")
      expect(response.body).to include("Second notification")
    end
  end

  describe "GET /notifications/:id" do
    let!(:notification) { create(:notification, user: user, title: "Test notification", read_at: nil) }

    it "returns a success response" do
      get notification_path(notification)

      expect(response).to have_http_status(:ok)
    end

    it "marks the notification as read" do
      expect {
        get notification_path(notification)
      }.to change { notification.reload.read_at }.from(nil)
    end

    context "when notification belongs to another user" do
      let!(:other_notification) { create(:notification) }

      it "returns not found" do
        get notification_path(other_notification)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /notifications/:id" do
    let!(:notification) { create(:notification, user: user) }

    it "deletes the notification" do
      expect {
        delete notification_path(notification)
      }.to change(Notification, :count).by(-1)
    end

    it "redirects to the notifications list" do
      delete notification_path(notification)

      expect(response).to redirect_to(notifications_path)
    end
  end

  describe "POST /notifications/mark_all_as_read" do
    let!(:notification1) { create(:notification, user: user, read_at: nil) }
    let!(:notification2) { create(:notification, user: user, read_at: nil) }
    let!(:other_notification) { create(:notification, read_at: nil) }

    it "marks all user notifications as read" do
      post mark_all_as_read_notifications_path

      expect(notification1.reload.read_at).to be_present
      expect(notification2.reload.read_at).to be_present
      expect(other_notification.reload.read_at).to be_nil
    end

    it "redirects to the notifications list" do
      post mark_all_as_read_notifications_path

      expect(response).to redirect_to(notifications_path)
    end
  end

  context "when not authenticated" do
    before { sign_out }

    it "redirects to sign in" do
      get notifications_path

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
