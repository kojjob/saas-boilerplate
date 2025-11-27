# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    let(:account) { create(:account, name: "Test Company") }
    let(:inviter) { create(:user, first_name: "John", last_name: "Doe") }
    let(:membership) do
      create(
        :membership,
        account: account,
        invitation_email: "invitee@example.com",
        invitation_token: "test-token-123",
        invited_by: inviter,
        role: "member"
      )
    end

    let(:mail) { described_class.invite(membership) }

    it "renders the headers" do
      expect(mail.to).to eq([ "invitee@example.com" ])
      expect(mail.subject).to eq("You've been invited to join Test Company")
    end

    it "renders the body with account name" do
      expect(mail.body.encoded).to include("Test Company")
    end

    it "includes the accept invitation URL" do
      expect(mail.body.encoded).to include("test-token-123")
    end

    it "sets the from address correctly" do
      expect(mail.from).to eq([ "from@example.com" ])
    end

    context "when membership has different roles" do
      let(:admin_membership) do
        create(
          :membership,
          account: account,
          invitation_email: "admin@example.com",
          invitation_token: "admin-token",
          invited_by: inviter,
          role: "admin"
        )
      end

      it "sends email for admin invitations" do
        admin_mail = described_class.invite(admin_membership)
        expect(admin_mail.to).to eq([ "admin@example.com" ])
      end
    end
  end
end
