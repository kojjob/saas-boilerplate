# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordResetMailer, type: :mailer do
  describe "#reset_email" do
    let(:user) do
      create(:user,
        email: "user@example.com",
        reset_password_token: "reset-token-abc123"
      )
    end

    let(:mail) { described_class.reset_email(user) }

    it "renders the headers" do
      expect(mail.to).to eq([ "user@example.com" ])
      expect(mail.subject).to eq("Reset your password")
    end

    it "renders the body with reset URL" do
      expect(mail.body.encoded).to include("reset-token-abc123")
    end

    it "sets the from address correctly" do
      expect(mail.from).to eq([ "noreply@example.com" ])
    end

    it "includes password reset instructions" do
      expect(mail.body.encoded).to match(/reset|password/i)
    end
  end
end
