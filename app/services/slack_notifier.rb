# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class SlackNotifier
  SEVERITY_COLORS = {
    info: "#36a64f",      # Green
    warning: "#ffcc00",   # Yellow
    error: "#ff6600",     # Orange
    critical: "#ff0000"   # Red
  }.freeze

  class << self
    def notify(alert)
      webhook_url = ENV.fetch("SLACK_WEBHOOK_URL", nil)

      unless webhook_url.present?
        Rails.logger.warn("Slack webhook URL not configured - notification skipped")
        return false
      end

      payload = build_alert_payload(alert)
      send_to_slack(webhook_url, payload)
    end

    def send_message(text, channel: nil, username: nil, icon_emoji: nil)
      webhook_url = ENV.fetch("SLACK_WEBHOOK_URL", nil)

      unless webhook_url.present?
        Rails.logger.warn("Slack webhook URL not configured - message skipped")
        return false
      end

      payload = {
        text: text
      }
      payload[:channel] = channel if channel
      payload[:username] = username if username
      payload[:icon_emoji] = icon_emoji if icon_emoji

      send_to_slack(webhook_url, payload)
    end

    private

    def build_alert_payload(alert)
      {
        attachments: [
          {
            color: SEVERITY_COLORS[alert.severity.to_sym],
            title: alert.title,
            text: alert.message,
            fields: build_fields(alert),
            footer: "Alert System",
            ts: alert.created_at.to_i
          }
        ]
      }
    end

    def build_fields(alert)
      fields = [
        {
          title: "Severity",
          value: alert.severity.titleize,
          short: true
        },
        {
          title: "Type",
          value: alert.alert_type.titleize,
          short: true
        }
      ]

      if alert.account.present?
        fields << {
          title: "Account",
          value: alert.account.name || alert.account.id,
          short: true
        }
      end

      if alert.alertable.present?
        fields << {
          title: "Related To",
          value: "#{alert.alertable_type} ##{alert.alertable_id}",
          short: true
        }
      end

      fields
    end

    def send_to_slack(webhook_url, payload)
      uri = URI.parse(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)

      if response.code.to_i == 200
        true
      else
        Rails.logger.error("Slack notification failed: #{response.code} - #{response.body}")
        false
      end
    rescue StandardError => e
      Rails.logger.error("Slack notification error: #{e.message}")
      false
    end
  end
end
