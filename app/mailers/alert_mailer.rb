# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  def alert_notification(alert, recipient)
    @alert = alert
    @account = alert.account

    subject = build_subject(alert)

    mail(to: recipient, subject: subject)
  end

  def daily_digest(alerts, recipient, account)
    @alerts = alerts
    @account = account
    @alert_count = alerts.count
    @severity_breakdown = alerts.group(:severity).count

    mail(
      to: recipient,
      subject: "[#{company_name}] Daily Alert Digest - #{Date.current.strftime('%B %d, %Y')}"
    )
  end

  private

  def build_subject(alert)
    prefix = case alert.severity.to_sym
             when :critical then "[CRITICAL]"
             when :error then "[ERROR]"
             when :warning then "[WARNING]"
             else "[INFO]"
             end

    "#{prefix} #{alert.title} - #{company_name}"
  end
end
