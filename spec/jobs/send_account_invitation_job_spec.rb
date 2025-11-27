# frozen_string_literal: true

require "rails_helper"

RSpec.describe SendAccountInvitationJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inviter) { create(:user) }
  let(:membership) do
    Membership.invite!(
      account: account,
      email: "newuser@example.com",
      role: :member,
      invited_by: inviter
    )
  end

  describe "#perform" do
    it "sends an invitation email" do
      expect {
        described_class.perform_now(membership.id, inviter.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends email to the membership invitation_email address" do
      described_class.perform_now(membership.id, inviter.id)
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include("newuser@example.com")
    end

    it "handles missing membership gracefully" do
      expect {
        described_class.perform_now(-1, inviter.id)
      }.not_to raise_error
    end

    it "handles missing inviter gracefully" do
      expect {
        described_class.perform_now(membership.id, -1)
      }.not_to raise_error
    end
  end

  describe "queue configuration" do
    it "is enqueued in the default queue" do
      expect {
        described_class.perform_later(membership.id, inviter.id)
      }.to have_enqueued_job.on_queue("default")
    end
  end

  describe "retry behavior" do
    it "retries on network errors" do
      retry_config = described_class.rescue_handlers.find { |h| h[0] == "Net::OpenTimeout" }
      expect(retry_config).to be_present
    end
  end
end
