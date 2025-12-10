# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimateMailer, type: :mailer do
  let(:account) { create(:account, name: "Test Business LLC") }
  let(:client) { create(:client, :with_address, account: account, email: "client@example.com", name: "John Smith") }
  let(:estimate) { create(:estimate, :with_line_items, account: account, client: client) }

  describe "#send_estimate" do
    let(:mail) { described_class.send_estimate(estimate) }

    it "renders the headers" do
      expect(mail.subject).to include(estimate.estimate_number)
      expect(mail.to).to eq([client.email])
    end

    it "sets the from address correctly" do
      expect(mail.from).to eq(["noreply@example.com"])
    end

    it "includes the estimate number in the body" do
      expect(mail.body.encoded).to include(estimate.estimate_number)
    end

    it "includes the total amount in the body" do
      expect(mail.body.encoded).to include(estimate.total_amount.to_s).or include(ActionController::Base.helpers.number_to_currency(estimate.total_amount))
    end

    it "includes the valid until date in the body" do
      expect(mail.body.encoded).to include(estimate.valid_until.strftime("%B %d, %Y")).or include(estimate.valid_until.strftime("%m/%d/%Y"))
    end

    it "includes the client name in the body" do
      expect(mail.body.encoded).to include(client.name)
    end

    it "attaches the PDF estimate" do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments.first
      expect(attachment.filename).to match(/estimate.*\.pdf/i)
      expect(attachment.content_type).to start_with("application/pdf")
    end

    it "generates a PDF attachment that starts with PDF header" do
      expect(mail.attachments.count).to be >= 1
      attachment = mail.attachments.first
      expect(attachment).not_to be_nil
      expect(attachment.body.raw_source).to start_with("%PDF")
    end

    context "with custom recipient" do
      let(:mail) { described_class.send_estimate(estimate, recipient: "alternate@example.com") }

      it "sends to the custom recipient" do
        expect(mail.to).to eq(["alternate@example.com"])
      end
    end

    context "with custom message" do
      let(:custom_message) { "Thank you for considering our services. Please review this estimate." }
      let(:mail) { described_class.send_estimate(estimate, message: custom_message) }

      it "includes the custom message in the body" do
        expect(mail.body.encoded).to include(custom_message)
      end
    end
  end
end
