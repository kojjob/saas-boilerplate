# frozen_string_literal: true

require "rails_helper"

RSpec.describe CacheHelper, type: :helper do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  # Define the methods on the helper that CacheHelper expects to be available
  before do
    # Define current_account method on helper
    helper.define_singleton_method(:current_account) { @_current_account }
    helper.instance_variable_set(:@_current_account, account)

    # Define current_user method on helper
    helper.define_singleton_method(:current_user) { @_current_user }
    helper.instance_variable_set(:@_current_user, user)
  end

  describe "#account_cache_key" do
    it "returns account-scoped key" do
      key = helper.account_cache_key
      expect(key).to eq("account/#{account.id}")
    end

    it "includes suffix when provided" do
      key = helper.account_cache_key("dashboard")
      expect(key).to eq("account/#{account.id}/dashboard")
    end

    it "returns nil without current account" do
      helper.instance_variable_set(:@_current_account, nil)
      expect(helper.account_cache_key).to be_nil
    end
  end

  describe "#user_cache_key" do
    it "returns user-scoped key" do
      key = helper.user_cache_key
      expect(key).to eq("user/#{user.id}")
    end

    it "includes suffix when provided" do
      key = helper.user_cache_key("preferences")
      expect(key).to eq("user/#{user.id}/preferences")
    end

    it "returns nil without current user" do
      helper.instance_variable_set(:@_current_user, nil)
      expect(helper.user_cache_key).to be_nil
    end
  end

  describe "#multi_cache_key" do
    it "combines multiple objects into key array" do
      keys = helper.multi_cache_key(account, user)
      expect(keys.length).to eq(2)
    end

    it "includes suffix when provided" do
      keys = helper.multi_cache_key(account, user, suffix: "combined")
      expect(keys.last).to eq("combined")
    end

    it "handles arrays of objects" do
      keys = helper.multi_cache_key([ account, user ])
      expect(keys.length).to eq(2)
    end

    it "uses cache_key_with_version when available" do
      allow(account).to receive(:cache_key_with_version).and_return("versioned_key")
      keys = helper.multi_cache_key(account)
      expect(keys.first).to eq("versioned_key")
    end
  end

  describe "#cached_dashboard_stats" do
    it "caches dashboard statistics" do
      stats = { total_users: 10, active_projects: 5 }

      result = helper.cached_dashboard_stats(account) { stats }
      expect(result).to eq(stats)
    end

    it "returns block result when account is nil" do
      stats = { total_users: 10 }

      result = helper.cached_dashboard_stats(nil) { stats }
      expect(result).to eq(stats)
    end

    it "uses cache on subsequent calls" do
      call_count = 0
      stats = { count: 0 }

      # First call
      helper.cached_dashboard_stats(account) do
        call_count += 1
        stats
      end

      # Second call - should use cache
      helper.cached_dashboard_stats(account) do
        call_count += 1
        stats
      end

      # Block should only be called once due to caching
      expect(call_count).to eq(1)
    end
  end

  describe "#cached_api_response" do
    it "caches API responses" do
      response = { data: "test" }

      result = helper.cached_api_response("test_key") { response }
      expect(result).to eq(response)
    end

    it "uses custom expiry" do
      response = { data: "test" }

      result = helper.cached_api_response("custom_key", expires_in: 30.minutes) { response }
      expect(result).to eq(response)
    end
  end

  describe "#cached_count" do
    it "caches count for a relation" do
      relation = User.all

      # First call
      count = helper.cached_count(relation)
      expect(count).to eq(User.count)
    end

    it "accepts custom key suffix" do
      relation = User.all

      count = helper.cached_count(relation, "active")
      expect(count).to eq(User.count)
    end
  end
end
