# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:alert) { create(:alert, account: account, title: "Test Alert", message: "Test message", severity: :warning) }
  let(:recipient) { "test@example.com" }

  describe "#alert_notification" do
    let(:mail) { described_class.alert_notification(alert, recipient) }

    it "renders the headers" do
      expect(mail.to).to eq([recipient])
      expect(mail.subject).to include("Test Alert")
    end

    it "includes severity prefix in subject" do
      expect(mail.subject).to include("[WARNING]")
    end

    it "renders the body" do
      expect(mail.html_part.body.encoded).to include("Test Alert")
      expect(mail.html_part.body.encoded).to include("Test message")
    end

    it "includes text version" do
      expect(mail.text_part.body.encoded).to include("Test Alert")
      expect(mail.text_part.body.encoded).to include("Test message")
    end

    context "with critical severity" do
      let(:alert) { create(:alert, account: account, title: "Critical Alert", severity: :critical) }

      it "includes CRITICAL prefix" do
        expect(mail.subject).to include("[CRITICAL]")
      end
    end

    context "with error severity" do
      let(:alert) { create(:alert, account: account, title: "Error Alert", severity: :error) }

      it "includes ERROR prefix" do
        expect(mail.subject).to include("[ERROR]")
      end
    end

    context "with info severity" do
      let(:alert) { create(:alert, account: account, title: "Info Alert", severity: :info) }

      it "includes INFO prefix" do
        expect(mail.subject).to include("[INFO]")
      end
    end
  end

  describe "#daily_digest" do
    let(:alerts) do
      create_list(:alert, 3, account: account, severity: :info) +
        create_list(:alert, 2, account: account, severity: :warning)
    end
    let(:mail) { described_class.daily_digest(Alert.where(id: alerts.map(&:id)), recipient, account) }

    it "renders the headers" do
      expect(mail.to).to eq([recipient])
      expect(mail.subject).to include("Daily Alert Digest")
    end

    it "includes the date in the subject" do
      expect(mail.subject).to include(Date.current.strftime("%B %d, %Y"))
    end

    it "renders the total alert count" do
      expect(mail.html_part.body.encoded).to include("5")
    end

    it "includes text version" do
      expect(mail.text_part.body.encoded).to include("Total Alerts: 5")
    end

    it "shows severity breakdown" do
      expect(mail.html_part.body.encoded).to include("Info")
      expect(mail.html_part.body.encoded).to include("Warning")
    end
  end
end
