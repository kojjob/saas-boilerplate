# frozen_string_literal: true

# Job to pre-warm cache with frequently accessed data
# Run periodically or after deployment to ensure fast response times
class CacheWarmupJob < ApplicationJob
  queue_as :maintenance

  # Warm up cache for commonly accessed data
  # @param scope [String] Optional scope to limit warmup ('all', 'accounts', 'users')
  def perform(scope = "all")
    Rails.logger.info "[CacheWarmup] Starting cache warmup for scope: #{scope}"

    case scope
    when "all"
      warmup_accounts
      warmup_users
      warmup_counts
    when "accounts"
      warmup_accounts
    when "users"
      warmup_users
    when "counts"
      warmup_counts
    else
      Rails.logger.warn "[CacheWarmup] Unknown scope: #{scope}"
    end

    Rails.logger.info "[CacheWarmup] Cache warmup completed"
  end

  private

  # Pre-cache recently active accounts
  def warmup_accounts
    return unless defined?(Account) && Account.table_exists?

    # Cache the most recently active accounts
    Account.order(updated_at: :desc).limit(100).find_each do |account|
      Rails.cache.fetch(Account.cache_key_for(account.id), expires_in: 1.hour) { account }
    rescue StandardError => e
      Rails.logger.error "[CacheWarmup] Error warming account #{account.id}: #{e.message}"
    end

    Rails.logger.info "[CacheWarmup] Warmed up account cache"
  end

  # Pre-cache recently active users
  def warmup_users
    return unless defined?(User) && User.table_exists?

    # Cache users who have been active recently
    active_users = User.where("updated_at > ?", 7.days.ago)
                       .order(updated_at: :desc)
                       .limit(500)

    active_users.find_each do |user|
      Rails.cache.fetch(User.cache_key_for(user.id), expires_in: 1.hour) { user }
    rescue StandardError => e
      Rails.logger.error "[CacheWarmup] Error warming user #{user.id}: #{e.message}"
    end

    Rails.logger.info "[CacheWarmup] Warmed up user cache"
  end

  # Pre-cache commonly used counts
  def warmup_counts
    counts = {}

    if defined?(User) && User.table_exists?
      counts[:total_users] = Rails.cache.fetch("counts/users/total", expires_in: 15.minutes) { User.count }
      counts[:active_users] = Rails.cache.fetch("counts/users/active", expires_in: 15.minutes) do
        User.where("updated_at > ?", 30.days.ago).count
      end
    end

    if defined?(Account) && Account.table_exists?
      counts[:total_accounts] = Rails.cache.fetch("counts/accounts/total", expires_in: 15.minutes) { Account.count }
    end

    Rails.logger.info "[CacheWarmup] Warmed up count cache: #{counts}"
  end
end
