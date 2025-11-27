# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  # Callbacks
  before_create :set_last_active

  # Scopes
  scope :active, -> { where("created_at > ?", 30.days.ago) }
  scope :recent, -> { order(created_at: :desc) }

  def touch_last_active!
    update_column(:last_active_at, Time.current)
  end

  def expired?
    created_at < 30.days.ago
  end

  def device_info
    return "Unknown" if user_agent.blank?

    # Simple device detection
    case user_agent
    when /iPhone/i
      "iPhone"
    when /iPad/i
      "iPad"
    when /Android/i
      "Android"
    when /Mac/i
      "Mac"
    when /Windows/i
      "Windows"
    when /Linux/i
      "Linux"
    else
      "Unknown"
    end
  end

  def browser_info
    return "Unknown" if user_agent.blank?

    case user_agent
    when /Chrome/i
      "Chrome"
    when /Firefox/i
      "Firefox"
    when /Safari/i
      "Safari"
    when /Edge/i
      "Edge"
    when /Opera/i
      "Opera"
    else
      "Unknown"
    end
  end

  private

  def set_last_active
    self.last_active_at = Time.current
  end
end
