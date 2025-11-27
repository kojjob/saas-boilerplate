# frozen_string_literal: true

# Helper methods for caching in views and controllers
module CacheHelper
  # Cache key for the current account context
  # Use this when caching data that's scoped to an account
  #
  # @param suffix [String] Optional suffix for the cache key
  # @return [String] Account-scoped cache key
  def account_cache_key(suffix = nil)
    return nil unless current_account

    key = "account/#{current_account.id}"
    key += "/#{suffix}" if suffix.present?
    key
  end

  # Cache key for user-specific data
  # Use this when caching data that's scoped to a user
  #
  # @param suffix [String] Optional suffix for the cache key
  # @return [String] User-scoped cache key
  def user_cache_key(suffix = nil)
    return nil unless current_user

    key = "user/#{current_user.id}"
    key += "/#{suffix}" if suffix.present?
    key
  end

  # Generate a versioned cache key based on multiple objects
  # Automatically invalidates when any object changes
  #
  # @param objects [Array<ApplicationRecord>] Objects to include in key
  # @param suffix [String] Optional suffix
  # @return [Array] Cache key array for use with cache helper
  def multi_cache_key(*objects, suffix: nil)
    keys = objects.flatten.map do |obj|
      if obj.respond_to?(:cache_key_with_version)
        obj.cache_key_with_version
      elsif obj.respond_to?(:cache_key)
        obj.cache_key
      else
        obj.to_s
      end
    end
    keys << suffix if suffix.present?
    keys
  end

  # Cache dashboard statistics with auto-expiry
  # Dashboard stats are cached for 5 minutes to balance freshness vs performance
  #
  # @param account [Account] The account to get stats for
  # @yield Block that generates the stats
  # @return [Hash] The cached or freshly computed stats
  def cached_dashboard_stats(account, &block)
    return yield unless account

    Rails.cache.fetch(
      "dashboard_stats/#{account.id}/#{Time.current.to_i / 300}",
      expires_in: 5.minutes,
      &block
    )
  end

  # Cache expensive API responses
  # Useful for external API calls that don't change frequently
  #
  # @param key [String] Unique cache key
  # @param expires_in [ActiveSupport::Duration] Cache duration
  # @yield Block that fetches the data
  # @return [Object] The cached or freshly fetched data
  def cached_api_response(key, expires_in: 15.minutes, &block)
    Rails.cache.fetch("api_response/#{key}", expires_in: expires_in, &block)
  end

  # Cache collection counts with short TTL
  # Counts change frequently but are expensive to compute for large collections
  #
  # @param relation [ActiveRecord::Relation] The relation to count
  # @param key_suffix [String] Suffix for cache differentiation
  # @return [Integer] The cached or computed count
  def cached_count(relation, key_suffix = nil)
    cache_key = "count/#{relation.model.name}/#{relation.to_sql.hash}"
    cache_key += "/#{key_suffix}" if key_suffix.present?

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      relation.count
    end
  end
end
