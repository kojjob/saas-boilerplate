# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe SlackNotifier, type: :service do
  let(:account) { create(:account) }
  let(:alert) { create(:alert, account: account, title: "Test Alert", message: "Test message", severity: :warning) }
  let(:webhook_url) { "https://example.com/slack-test-webhook" }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  after do
    WebMock.allow_net_connect!
  end

  describe ".notify" do
    context "when webhook URL is configured" do
      before do
        allow(ENV).to receive(:fetch).with("SLACK_WEBHOOK_URL", nil).and_return(webhook_url)
      end

      it "sends a notification to Slack" do
        stub_request(:post, webhook_url)
          .with(
            headers: { "Content-Type" => "application/json" }
          )
          .to_return(status: 200, body: "ok")

        result = SlackNotifier.notify(alert)

        expect(result).to be true
        expect(WebMock).to have_requested(:post, webhook_url)
      end

      it "includes alert information in the payload" do
        stub_request(:post, webhook_url)
          .to_return(status: 200, body: "ok")

        SlackNotifier.notify(alert)

        expect(WebMock).to have_requested(:post, webhook_url).with { |req|
          body = JSON.parse(req.body)
          body["attachments"][0]["title"] == "Test Alert"
        }
      end

      it "uses severity-based colors" do
        stub_request(:post, webhook_url).to_return(status: 200, body: "ok")

        SlackNotifier.notify(alert)

        expect(WebMock).to have_requested(:post, webhook_url).with { |req|
          body = JSON.parse(req.body)
          body["attachments"][0]["color"] == "#ffcc00" # warning color
        }
      end

      it "returns false when Slack returns an error" do
        stub_request(:post, webhook_url)
          .to_return(status: 500, body: "server_error")

        result = SlackNotifier.notify(alert)

        expect(result).to be false
      end

      it "handles network errors gracefully" do
        stub_request(:post, webhook_url)
          .to_timeout

        result = SlackNotifier.notify(alert)

        expect(result).to be false
      end
    end

    context "when webhook URL is not configured" do
      before do
        allow(ENV).to receive(:fetch).with("SLACK_WEBHOOK_URL", nil).and_return(nil)
      end

      it "returns false without making a request" do
        result = SlackNotifier.notify(alert)

        expect(result).to be false
        expect(WebMock).not_to have_requested(:post, webhook_url)
      end

      it "logs a warning message" do
        allow(Rails.logger).to receive(:warn)

        SlackNotifier.notify(alert)

        expect(Rails.logger).to have_received(:warn).with(/Slack webhook URL not configured/)
      end
    end
  end

  describe ".send_message" do
    before do
      allow(ENV).to receive(:fetch).with("SLACK_WEBHOOK_URL", nil).and_return(webhook_url)
    end

    it "sends a simple text message" do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: "ok")

      result = SlackNotifier.send_message("Hello, Slack!")

      expect(result).to be true
      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["text"] == "Hello, Slack!"
      }
    end

    it "allows customizing channel" do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: "ok")

      SlackNotifier.send_message("Test", channel: "#alerts")

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["channel"] == "#alerts"
      }
    end

    it "allows customizing username" do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: "ok")

      SlackNotifier.send_message("Test", username: "Alert Bot")

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["username"] == "Alert Bot"
      }
    end

    it "allows customizing icon_emoji" do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: "ok")

      SlackNotifier.send_message("Test", icon_emoji: ":warning:")

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["icon_emoji"] == ":warning:"
      }
    end
  end

  describe "severity colors" do
    before do
      allow(ENV).to receive(:fetch).with("SLACK_WEBHOOK_URL", nil).and_return(webhook_url)
      stub_request(:post, webhook_url).to_return(status: 200, body: "ok")
    end

    it "uses green for info severity" do
      info_alert = create(:alert, account: account, severity: :info)
      SlackNotifier.notify(info_alert)

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["attachments"][0]["color"] == "#36a64f"
      }
    end

    it "uses yellow for warning severity" do
      warning_alert = create(:alert, account: account, severity: :warning)
      SlackNotifier.notify(warning_alert)

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["attachments"][0]["color"] == "#ffcc00"
      }
    end

    it "uses orange for error severity" do
      error_alert = create(:alert, account: account, severity: :error)
      SlackNotifier.notify(error_alert)

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["attachments"][0]["color"] == "#ff6600"
      }
    end

    it "uses red for critical severity" do
      critical_alert = create(:alert, account: account, severity: :critical)
      SlackNotifier.notify(critical_alert)

      expect(WebMock).to have_requested(:post, webhook_url).with { |req|
        body = JSON.parse(req.body)
        body["attachments"][0]["color"] == "#ff0000"
      }
    end
  end
end
