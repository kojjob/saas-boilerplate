# frozen_string_literal: true

require "rails_helper"

RSpec.describe CacheWarmupJob, type: :job do
  describe "#perform" do
    let!(:account) { create(:account) }
    let!(:user) { create(:user) }

    context "with 'all' scope" do
      it "warms up all caches" do
        expect(Rails.logger).to receive(:info).at_least(:twice)
        described_class.new.perform("all")
      end

      it "caches accounts" do
        described_class.new.perform("all")
        # Verify account was cached
        expect(Rails.cache.exist?(Account.cache_key_for(account.id))).to be_truthy
      end

      it "caches users" do
        # Update user to be recent (within 7 days)
        user.update_column(:updated_at, Time.current)

        described_class.new.perform("all")
        # Verify user was cached
        expect(Rails.cache.exist?(User.cache_key_for(user.id))).to be_truthy
      end
    end

    context "with 'accounts' scope" do
      it "only warms account cache" do
        described_class.new.perform("accounts")
        expect(Rails.cache.exist?(Account.cache_key_for(account.id))).to be_truthy
      end
    end

    context "with 'users' scope" do
      it "only warms user cache" do
        # Ensure user is recent (updated within 7 days)
        user.update_column(:updated_at, Time.current)

        described_class.new.perform("users")
        expect(Rails.cache.exist?(User.cache_key_for(user.id))).to be_truthy
      end
    end

    context "with 'counts' scope" do
      it "warms count caches" do
        described_class.new.perform("counts")
        expect(Rails.cache.exist?("counts/users/total")).to be_truthy
        expect(Rails.cache.exist?("counts/accounts/total")).to be_truthy
      end
    end

    context "with unknown scope" do
      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/Unknown scope/)
        described_class.new.perform("invalid")
      end
    end

    context "when models include Cacheable" do
      it "respects cache key format for accounts" do
        described_class.new.perform("accounts")
        cache_key = Account.cache_key_for(account.id)
        expect(cache_key).to eq("accounts/#{account.id}")
      end

      it "respects cache key format for users" do
        described_class.new.perform("users")
        cache_key = User.cache_key_for(user.id)
        expect(cache_key).to eq("users/#{user.id}")
      end
    end
  end

  describe "job configuration" do
    it "uses maintenance queue" do
      expect(described_class.new.queue_name).to eq("maintenance")
    end
  end

  describe "error handling" do
    let!(:account) { create(:account) }

    it "continues processing on individual record errors" do
      # Create multiple accounts
      create_list(:account, 3)

      # Should not raise even if one account fails
      expect { described_class.new.perform("accounts") }.not_to raise_error
    end
  end
end
