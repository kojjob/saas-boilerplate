# frozen_string_literal: true

# Job to clean up expired user sessions
# Runs as a recurring job to maintain database hygiene
class CleanupExpiredSessionsJob < ApplicationJob
  queue_as :maintenance

  DEFAULT_EXPIRY_DAYS = 30

  # @param expiry_days [Integer] Number of days after which sessions are considered expired
  def perform(expiry_days: DEFAULT_EXPIRY_DAYS)
    expired_count = Session.where("created_at < ?", expiry_days.days.ago).delete_all
    Rails.logger.info "[CleanupExpiredSessionsJob] Deleted #{expired_count} expired sessions older than #{expiry_days} days"
    { deleted_count: expired_count }
  end
end
