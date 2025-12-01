# frozen_string_literal: true

class AlertService
  class << self
    def notify(account:, alert_type:, title:, message: nil, severity: :info, alertable: nil, channels: [], recipients: [], metadata: {})
      alert = create_alert(
        account: account,
        alert_type: alert_type,
        severity: severity,
        title: title,
        message: message,
        alertable: alertable,
        metadata: metadata
      )

      dispatch_to_channels(alert, channels, recipients)
      alert
    end

    def critical(account:, alert_type:, title:, message: nil, alertable: nil, channels: [:email, :slack], recipients: [], metadata: {})
      notify(
        account: account,
        alert_type: alert_type,
        severity: :critical,
        title: title,
        message: message,
        alertable: alertable,
        channels: channels,
        recipients: recipients,
        metadata: metadata
      )
    end

    def warning(account:, alert_type:, title:, message: nil, alertable: nil, channels: [], recipients: [], metadata: {})
      notify(
        account: account,
        alert_type: alert_type,
        severity: :warning,
        title: title,
        message: message,
        alertable: alertable,
        channels: channels,
        recipients: recipients,
        metadata: metadata
      )
    end

    def info(account:, alert_type:, title:, message: nil, alertable: nil, channels: [], recipients: [], metadata: {})
      notify(
        account: account,
        alert_type: alert_type,
        severity: :info,
        title: title,
        message: message,
        alertable: alertable,
        channels: channels,
        recipients: recipients,
        metadata: metadata
      )
    end

    private

    def create_alert(account:, alert_type:, severity:, title:, message:, alertable:, metadata:)
      Alert.create!(
        account: account,
        alert_type: alert_type,
        severity: severity,
        title: title,
        message: message,
        alertable: alertable,
        metadata: metadata,
        status: :pending
      )
    end

    def dispatch_to_channels(alert, channels, recipients)
      channels.each do |channel|
        case channel.to_sym
        when :email
          send_email_notification(alert, recipients)
        when :slack
          send_slack_notification(alert)
        end
      end
    end

    def send_email_notification(alert, recipients)
      recipients.each do |recipient|
        AlertMailer.alert_notification(alert, recipient).deliver_later
      end
    rescue StandardError => e
      Rails.logger.error("Failed to send email alert: #{e.message}")
      alert.mark_as_failed!(e.message)
    end

    def send_slack_notification(alert)
      SlackNotifier.notify(alert)
    rescue StandardError => e
      Rails.logger.error("Failed to send Slack alert: #{e.message}")
      alert.mark_as_failed!(e.message)
    end
  end
end
