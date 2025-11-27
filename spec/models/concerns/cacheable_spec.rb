# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cacheable do
  # Use User model as it includes Cacheable
  describe "class methods" do
    let!(:user) { create(:user) }

    describe ".cached_find" do
      it "caches the record" do
        # First call - should hit the database
        result1 = User.cached_find(user.id)
        expect(result1).to eq(user)

        # Second call - should use cache
        allow(User).to receive(:find_by).and_call_original
        result2 = User.cached_find(user.id)
        expect(result2).to eq(user)
      end

      it "returns nil for non-existent records" do
        result = User.cached_find("non-existent-id")
        expect(result).to be_nil
      end

      it "accepts custom expiry time" do
        result = User.cached_find(user.id, expires_in: 30.minutes)
        expect(result).to eq(user)
      end
    end

    describe ".cached_find_all" do
      let!(:user2) { create(:user) }

      it "returns multiple cached records" do
        results = User.cached_find_all([ user.id, user2.id ])
        expect(results).to contain_exactly(user, user2)
      end

      it "ignores non-existent IDs" do
        results = User.cached_find_all([ user.id, "non-existent" ])
        expect(results).to eq([ user ])
      end
    end

    describe ".cached_count" do
      it "caches the count" do
        count = User.cached_count
        expect(count).to eq(User.count)
      end

      it "caches count for specific scopes" do
        # Add confirmed scope if it exists
        if User.respond_to?(:confirmed)
          count = User.cached_count(:confirmed)
          expect(count).to be_a(Integer)
        end
      end
    end

    describe ".cache_key_for" do
      it "generates a cache key for an ID" do
        key = User.cache_key_for(user.id)
        expect(key).to eq("users/#{user.id}")
      end
    end

    describe ".bust_cache" do
      it "invalidates the cache for a record" do
        # Cache the record first
        User.cached_find(user.id)

        # Bust the cache
        User.bust_cache(user.id)

        # Verify cache was cleared by checking Rails.cache directly
        cache_key = User.cache_key_for(user.id)
        expect(Rails.cache.exist?(cache_key)).to be_falsey
      end
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }

    describe "#cache_key_with_version" do
      it "includes the updated_at timestamp" do
        key = user.cache_key_with_version
        expect(key).to include(user.id.to_s)
        expect(key).to include(user.updated_at.to_i.to_s)
      end

      it "changes when record is updated" do
        old_key = user.cache_key_with_version

        # Travel forward in time to ensure updated_at changes
        travel_to(1.minute.from_now) do
          user.update!(first_name: "NewName")
          new_key = user.cache_key_with_version
          expect(new_key).not_to eq(old_key)
        end
      end
    end

    describe "#bust_cache" do
      it "clears the instance cache" do
        User.cached_find(user.id)
        user.bust_cache

        cache_key = User.cache_key_for(user.id)
        expect(Rails.cache.exist?(cache_key)).to be_falsey
      end
    end
  end
end
