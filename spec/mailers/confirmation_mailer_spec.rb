# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConfirmationMailer, type: :mailer do
  describe "#confirmation_email" do
    let(:user) do
      create(:user,
        email: "newuser@example.com",
        confirmation_token: "confirm-token-xyz789"
      )
    end

    let(:mail) { described_class.confirmation_email(user) }

    it "renders the headers" do
      expect(mail.to).to eq([ "newuser@example.com" ])
      expect(mail.subject).to eq("Confirm your email address")
    end

    it "renders the body with confirmation URL" do
      expect(mail.body.encoded).to include("confirm-token-xyz789")
    end

    it "sets the from address correctly" do
      expect(mail.from).to eq([ "noreply@example.com" ])
    end

    it "includes email confirmation instructions" do
      expect(mail.body.encoded).to match(/confirm|email/i)
    end
  end
end
