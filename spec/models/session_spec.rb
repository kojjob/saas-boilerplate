# frozen_string_literal: true

require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "callbacks" do
    describe "#set_last_active" do
      it "sets last_active_at before creation" do
        user = create(:user)
        session = Session.create!(user: user, ip_address: "127.0.0.1")
        expect(session.last_active_at).to be_present
      end
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".active" do
      it "includes sessions created within 30 days" do
        recent_session = create(:session, user: user, created_at: 1.day.ago)
        expect(Session.active).to include(recent_session)
      end

      it "excludes sessions older than 30 days" do
        old_session = create(:session, user: user, created_at: 31.days.ago)
        expect(Session.active).not_to include(old_session)
      end
    end

    describe ".recent" do
      it "orders sessions by created_at descending" do
        old_session = create(:session, user: user, created_at: 2.days.ago)
        new_session = create(:session, user: user, created_at: 1.day.ago)

        expect(Session.recent.first).to eq(new_session)
        expect(Session.recent.last).to eq(old_session)
      end
    end
  end

  describe "#touch_last_active!" do
    let(:session) { create(:session) }

    it "updates last_active_at to current time" do
      freeze_time do
        session.touch_last_active!
        expect(session.last_active_at).to eq(Time.current)
      end
    end
  end

  describe "#expired?" do
    let(:user) { create(:user) }

    it "returns false for recent sessions" do
      session = create(:session, user: user, created_at: 1.day.ago)
      expect(session.expired?).to be false
    end

    it "returns true for sessions older than 30 days" do
      session = create(:session, user: user, created_at: 31.days.ago)
      expect(session.expired?).to be true
    end

    it "returns false for sessions exactly 30 days old" do
      session = create(:session, user: user, created_at: 30.days.ago + 1.hour)
      expect(session.expired?).to be false
    end
  end

  describe "#device_info" do
    let(:session) { create(:session) }

    it "returns 'Unknown' for blank user agent" do
      session.user_agent = nil
      expect(session.device_info).to eq("Unknown")
    end

    it "detects iPhone" do
      session.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"
      expect(session.device_info).to eq("iPhone")
    end

    it "detects iPad" do
      session.user_agent = "Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X)"
      expect(session.device_info).to eq("iPad")
    end

    it "detects Android" do
      session.user_agent = "Mozilla/5.0 (Linux; Android 10)"
      expect(session.device_info).to eq("Android")
    end

    it "detects Mac" do
      session.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
      expect(session.device_info).to eq("Mac")
    end

    it "detects Windows" do
      session.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
      expect(session.device_info).to eq("Windows")
    end

    it "detects Linux" do
      session.user_agent = "Mozilla/5.0 (X11; Linux x86_64)"
      expect(session.device_info).to eq("Linux")
    end

    it "returns 'Unknown' for unrecognized user agents" do
      session.user_agent = "SomeOtherAgent/1.0"
      expect(session.device_info).to eq("Unknown")
    end
  end

  describe "#browser_info" do
    let(:session) { create(:session) }

    it "returns 'Unknown' for blank user agent" do
      session.user_agent = nil
      expect(session.browser_info).to eq("Unknown")
    end

    it "detects Chrome" do
      session.user_agent = "Mozilla/5.0 Chrome/91.0.4472.124"
      expect(session.browser_info).to eq("Chrome")
    end

    it "detects Firefox" do
      session.user_agent = "Mozilla/5.0 Firefox/89.0"
      expect(session.browser_info).to eq("Firefox")
    end

    it "detects Safari" do
      session.user_agent = "Mozilla/5.0 Safari/605.1.15"
      expect(session.browser_info).to eq("Safari")
    end

    it "detects Edge" do
      session.user_agent = "Mozilla/5.0 Edge/91.0.864.59"
      expect(session.browser_info).to eq("Edge")
    end

    it "detects Opera" do
      session.user_agent = "Mozilla/5.0 Opera/9.80"
      expect(session.browser_info).to eq("Opera")
    end

    it "returns 'Unknown' for unrecognized browsers" do
      session.user_agent = "SomeUnknownBrowser/1.0"
      expect(session.browser_info).to eq("Unknown")
    end
  end
end
