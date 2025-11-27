# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExportDataJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:account) { create(:account) }

  before do
    create(:membership, user: user, account: account, role: :owner)
  end

  describe "#perform" do
    it "creates an export for the user" do
      # Perform job and check result
      result = described_class.perform_now(user.id, "users")
      expect(result).to include(:success)
    end

    it "handles invalid export type gracefully" do
      expect {
        described_class.perform_now(user.id, "invalid_type")
      }.not_to raise_error
    end

    it "handles missing user gracefully" do
      expect {
        described_class.perform_now(-1, "users")
      }.not_to raise_error
    end
  end

  describe "queue configuration" do
    it "is enqueued in the exports queue" do
      expect {
        described_class.perform_later(user.id, "users")
      }.to have_enqueued_job.on_queue("exports")
    end
  end

  describe "supported export types" do
    it "supports users export" do
      expect(described_class::SUPPORTED_EXPORT_TYPES).to include("users")
    end

    it "supports accounts export" do
      expect(described_class::SUPPORTED_EXPORT_TYPES).to include("accounts")
    end

    it "supports activity_logs export" do
      expect(described_class::SUPPORTED_EXPORT_TYPES).to include("activity_logs")
    end
  end
end
