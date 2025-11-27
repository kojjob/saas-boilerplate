# frozen_string_literal: true

# Caching concern for models
# Provides consistent caching patterns using Solid Cache
module Cacheable
  extend ActiveSupport::Concern

  included do
    # Touch parent associations to bust cache
    after_commit :touch_cached_associations, on: %i[create update destroy]
  end

  class_methods do
    # Fetch a record by ID with caching
    # @param id [String, Integer] The record ID
    # @param expires_in [ActiveSupport::Duration] Cache duration (default: 1 hour)
    # @return [ApplicationRecord, nil] The found record or nil
    def cached_find(id, expires_in: 1.hour)
      Rails.cache.fetch(cache_key_for(id), expires_in: expires_in) do
        find_by(id: id)
      end
    end

    # Fetch multiple records by IDs with caching
    # @param ids [Array<String, Integer>] The record IDs
    # @param expires_in [ActiveSupport::Duration] Cache duration
    # @return [Array<ApplicationRecord>] Found records
    def cached_find_all(ids, expires_in: 1.hour)
      ids.map { |id| cached_find(id, expires_in: expires_in) }.compact
    end

    # Fetch a count with caching
    # @param scope_name [Symbol] Optional scope to apply
    # @param expires_in [ActiveSupport::Duration] Cache duration
    # @return [Integer] The count
    def cached_count(scope_name = nil, expires_in: 5.minutes)
      cache_key = "#{model_name.cache_key}/count/#{scope_name || 'all'}"
      Rails.cache.fetch(cache_key, expires_in: expires_in) do
        scope_name ? public_send(scope_name).count : count
      end
    end

    # Generate a cache key for a specific record ID
    # @param id [String, Integer] The record ID
    # @return [String] The cache key
    def cache_key_for(id)
      "#{model_name.cache_key}/#{id}"
    end

    # Invalidate the cache for a specific record
    # @param id [String, Integer] The record ID
    def bust_cache(id)
      Rails.cache.delete(cache_key_for(id))
    end

    # Invalidate all count caches for this model
    def bust_count_cache
      Rails.cache.delete_matched("#{model_name.cache_key}/count/*")
    end
  end

  # Instance cache key that includes updated_at for automatic invalidation
  # @return [String] Cache key with version
  def cache_key_with_version
    "#{self.class.model_name.cache_key}/#{id}-#{updated_at.to_i}"
  end

  # Invalidate this record's cache
  def bust_cache
    self.class.bust_cache(id)
    self.class.bust_count_cache
  end

  private

  # Override in models to specify associations to touch on cache invalidation
  def cached_associations
    []
  end

  def touch_cached_associations
    cached_associations.each do |association|
      record = public_send(association)
      record&.bust_cache if record.respond_to?(:bust_cache)
    end
  end
end
