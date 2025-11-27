# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user, :confirmed) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "subscribes to the user's notifications stream" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("notifications_#{user.id}")
    end
  end

  describe "#unsubscribed" do
    it "stops all streams" do
      subscribe
      unsubscribe

      expect(subscription).to_not have_streams
    end
  end

  describe "#mark_as_read" do
    let!(:notification) { create(:notification, user: user, read_at: nil) }

    it "marks the notification as read" do
      subscribe
      expect {
        perform :mark_as_read, notification_id: notification.id
      }.to change { notification.reload.read_at }.from(nil)
    end

    it "does not mark other users' notifications" do
      other_notification = create(:notification, read_at: nil)
      subscribe

      perform :mark_as_read, notification_id: other_notification.id

      expect(other_notification.reload.read_at).to be_nil
    end
  end

  describe "#mark_all_as_read" do
    let!(:notification1) { create(:notification, user: user, read_at: nil) }
    let!(:notification2) { create(:notification, user: user, read_at: nil) }
    let!(:other_notification) { create(:notification, read_at: nil) }

    it "marks all user's unread notifications as read" do
      subscribe

      perform :mark_all_as_read

      expect(notification1.reload.read_at).to be_present
      expect(notification2.reload.read_at).to be_present
    end

    it "does not mark other users' notifications" do
      subscribe

      perform :mark_all_as_read

      expect(other_notification.reload.read_at).to be_nil
    end

    it "broadcasts all_read action" do
      subscribe

      expect {
        perform :mark_all_as_read
      }.to have_broadcasted_to("notifications_#{user.id}").with(action: "all_read")
    end
  end
end
