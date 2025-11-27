# frozen_string_literal: true

require "rails_helper"

RSpec.describe CleanupExpiredSessionsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let!(:user) { create(:user) }
    let!(:current_session) { create(:session, user: user, created_at: 1.day.ago) }
    let!(:old_session) { create(:session, user: user, created_at: 31.days.ago) }
    let!(:very_old_session) { create(:session, user: user, created_at: 60.days.ago) }

    it "deletes sessions older than 30 days by default" do
      expect {
        described_class.perform_now
      }.to change(Session, :count).by(-2)
    end

    it "keeps recent sessions" do
      described_class.perform_now
      expect(Session.find_by(id: current_session.id)).to be_present
    end

    it "can accept custom expiry period" do
      # Only delete sessions older than 7 days
      expect {
        described_class.perform_now(expiry_days: 7)
      }.to change(Session, :count).by(-2)
    end
  end

  describe "queue configuration" do
    it "is enqueued in the maintenance queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job.on_queue("maintenance")
    end
  end
end
