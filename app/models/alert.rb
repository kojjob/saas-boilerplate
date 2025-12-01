# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :account
  belongs_to :alertable, polymorphic: true, optional: true

  enum :severity, { info: 0, warning: 1, error: 2, critical: 3 }
  enum :status, { pending: 0, sent: 1, failed: 2, acknowledged: 3 }

  validates :alert_type, presence: true
  validates :severity, presence: true
  validates :title, presence: true

  scope :unacknowledged, -> { where.not(status: :acknowledged) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { where("created_at > ?", 24.hours.ago) }
  scope :for_account, ->(account) { where(account: account) }

  def acknowledge!
    update!(status: :acknowledged, acknowledged_at: Time.current)
  end

  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_failed!(message)
    update!(status: :failed, error_message: message)
  end
end
