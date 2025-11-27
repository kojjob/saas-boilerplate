# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:notifiable).optional }
    it { should belong_to(:account).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:notification_type) }
  end

  describe "scopes" do
    describe ".unread" do
      let(:user) { create(:user, :confirmed) }
      let!(:unread_notification) { create(:notification, user: user, read_at: nil) }
      let!(:read_notification) { create(:notification, user: user, read_at: Time.current) }

      it "returns only unread notifications" do
        expect(Notification.unread).to contain_exactly(unread_notification)
      end
    end

    describe ".read" do
      let(:user) { create(:user, :confirmed) }
      let!(:unread_notification) { create(:notification, user: user, read_at: nil) }
      let!(:read_notification) { create(:notification, user: user, read_at: Time.current) }

      it "returns only read notifications" do
        expect(Notification.read).to contain_exactly(read_notification)
      end
    end

    describe ".recent" do
      let(:user) { create(:user, :confirmed) }
      let!(:old_notification) { create(:notification, user: user, created_at: 1.month.ago) }
      let!(:recent_notification) { create(:notification, user: user, created_at: 1.day.ago) }

      it "returns notifications in descending order by created_at" do
        results = Notification.recent
        expect(results.first).to eq(recent_notification)
        expect(results.last).to eq(old_notification)
      end
    end
  end

  describe "enums" do
    it "defines notification_type enum" do
      expect(described_class.notification_types).to include(
        "info" => 0,
        "success" => 1,
        "warning" => 2,
        "error" => 3
      )
    end
  end

  describe "#mark_as_read!" do
    let(:notification) { create(:notification, read_at: nil) }

    it "sets read_at to current time" do
      expect { notification.mark_as_read! }.to change { notification.read_at }.from(nil)
      expect(notification.read_at).to be_present
    end
  end

  describe "#unread?" do
    context "when read_at is nil" do
      let(:notification) { build(:notification, read_at: nil) }

      it "returns true" do
        expect(notification.unread?).to be true
      end
    end

    context "when read_at is set" do
      let(:notification) { build(:notification, read_at: Time.current) }

      it "returns false" do
        expect(notification.unread?).to be false
      end
    end
  end

  describe "broadcasting" do
    let(:user) { create(:user, :confirmed, :owner) }
    let(:notification) { build(:notification, user: user) }

    it "broadcasts to user's notification channel after create" do
      expect {
        notification.save!
      }.to have_broadcasted_to("notifications_#{user.id}").with { |data|
        expect(data[:notification][:title]).to eq(notification.title)
      }
    end
  end

  describe ".create_for_user" do
    let(:user) { create(:user, :confirmed) }

    it "creates a notification for the user" do
      notification = Notification.create_for_user(
        user: user,
        title: "Test Notification",
        body: "This is a test",
        notification_type: :info
      )

      expect(notification).to be_persisted
      expect(notification.user).to eq(user)
      expect(notification.title).to eq("Test Notification")
      expect(notification.body).to eq("This is a test")
      expect(notification.info?).to be true
    end
  end
end
