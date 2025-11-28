# frozen_string_literal: true

# Job to clean up expired user sessions
# Runs as a recurring job to maintain database hygiene
# Cleans up:
#   1. Sessions older than expiry_days (default 30 days)
#   2. Inactive sessions (no activity for inactive_days, default 7 days)
class CleanupExpiredSessionsJob < ApplicationJob
  queue_as :maintenance

  DEFAULT_EXPIRY_DAYS = 30
  DEFAULT_INACTIVE_DAYS = 7

  # @param expiry_days [Integer] Number of days after which sessions are considered expired
  # @param inactive_days [Integer] Number of days of inactivity after which sessions are cleaned up
  def perform(expiry_days: DEFAULT_EXPIRY_DAYS, inactive_days: DEFAULT_INACTIVE_DAYS)
    # Delete sessions older than expiry_days
    old_sessions_count = Session.where("created_at < ?", expiry_days.days.ago).delete_all

    # Delete sessions that haven't been active recently
    inactive_sessions_count = Session.where(
      "last_active_at IS NOT NULL AND last_active_at < ?",
      inactive_days.days.ago
    ).delete_all

    total_deleted = old_sessions_count + inactive_sessions_count

    Rails.logger.info(
      "[CleanupExpiredSessionsJob] Deleted #{total_deleted} sessions " \
      "(#{old_sessions_count} old, #{inactive_sessions_count} inactive)"
    )

    { deleted_count: total_deleted, old_sessions: old_sessions_count, inactive_sessions: inactive_sessions_count }
  end
end
