# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertService, type: :service do
  let(:account) { create(:account) }

  describe ".notify" do
    it "creates an alert with the provided attributes" do
      alert = AlertService.notify(
        account: account,
        alert_type: "test_alert",
        title: "Test Alert",
        message: "This is a test alert",
        severity: :warning
      )

      expect(alert).to be_persisted
      expect(alert.account).to eq(account)
      expect(alert.alert_type).to eq("test_alert")
      expect(alert.title).to eq("Test Alert")
      expect(alert.message).to eq("This is a test alert")
      expect(alert.severity).to eq("warning")
    end

    it "creates an alert with default severity of info" do
      alert = AlertService.notify(
        account: account,
        alert_type: "test_alert",
        title: "Test Alert"
      )

      expect(alert.severity).to eq("info")
    end

    it "can attach an alertable object" do
      invoice = create(:invoice, account: account)

      alert = AlertService.notify(
        account: account,
        alert_type: "invoice_alert",
        title: "Invoice Alert",
        alertable: invoice
      )

      expect(alert.alertable).to eq(invoice)
    end

    it "stores metadata" do
      alert = AlertService.notify(
        account: account,
        alert_type: "test_alert",
        title: "Test Alert",
        metadata: { key: "value", number: 42 }
      )

      expect(alert.metadata).to eq({ "key" => "value", "number" => 42 })
    end

    context "with email channel" do
      it "sends email notification to recipients" do
        allow(AlertMailer).to receive_message_chain(:alert_notification, :deliver_later)

        AlertService.notify(
          account: account,
          alert_type: "test_alert",
          title: "Test Alert",
          channels: [:email],
          recipients: ["test@example.com"]
        )

        expect(AlertMailer).to have_received(:alert_notification)
      end
    end

    context "with slack channel" do
      it "sends slack notification" do
        allow(SlackNotifier).to receive(:notify).and_return(true)

        AlertService.notify(
          account: account,
          alert_type: "test_alert",
          title: "Test Alert",
          channels: [:slack]
        )

        expect(SlackNotifier).to have_received(:notify)
      end
    end
  end

  describe ".critical" do
    it "creates an alert with critical severity" do
      allow(SlackNotifier).to receive(:notify).and_return(true)
      allow(AlertMailer).to receive_message_chain(:alert_notification, :deliver_later)

      alert = AlertService.critical(
        account: account,
        alert_type: "critical_alert",
        title: "Critical Alert"
      )

      expect(alert.severity).to eq("critical")
    end

    it "sends to both email and slack by default" do
      allow(SlackNotifier).to receive(:notify).and_return(true)
      allow(AlertMailer).to receive_message_chain(:alert_notification, :deliver_later)

      AlertService.critical(
        account: account,
        alert_type: "critical_alert",
        title: "Critical Alert",
        recipients: ["admin@example.com"]
      )

      expect(SlackNotifier).to have_received(:notify)
      expect(AlertMailer).to have_received(:alert_notification)
    end
  end

  describe ".warning" do
    it "creates an alert with warning severity" do
      alert = AlertService.warning(
        account: account,
        alert_type: "warning_alert",
        title: "Warning Alert"
      )

      expect(alert.severity).to eq("warning")
    end
  end

  describe ".info" do
    it "creates an alert with info severity" do
      alert = AlertService.info(
        account: account,
        alert_type: "info_alert",
        title: "Info Alert"
      )

      expect(alert.severity).to eq("info")
    end
  end
end
