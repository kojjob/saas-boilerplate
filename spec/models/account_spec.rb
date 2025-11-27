# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'validations' do
    subject { build(:account) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug).case_insensitive }
    it { should validate_uniqueness_of(:subdomain).case_insensitive.allow_nil }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_length_of(:slug).is_at_least(3).is_at_most(50) }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
  end

  describe 'slug generation' do
    it 'generates a slug from the name if not provided' do
      account = create(:account, name: 'My Company', slug: nil)
      expect(account.slug).to eq('my-company')
    end

    it 'handles duplicate slugs by appending a number' do
      create(:account, name: 'Test Company', slug: 'test-company')
      account = create(:account, name: 'Test Company', slug: nil)
      expect(account.slug).to match(/test-company-\d+/)
    end

    it 'preserves custom slugs' do
      account = create(:account, name: 'My Company', slug: 'custom-slug')
      expect(account.slug).to eq('custom-slug')
    end
  end

  describe 'subdomain validation' do
    it 'rejects reserved subdomains' do
      %w[www admin api app mail].each do |reserved|
        account = build(:account, subdomain: reserved)
        expect(account).not_to be_valid
        expect(account.errors[:subdomain]).to include('is reserved')
      end
    end

    it 'allows valid subdomains' do
      account = build(:account, subdomain: 'mycompany')
      expect(account).to be_valid
    end

    it 'rejects subdomains with special characters' do
      account = build(:account, subdomain: 'my_company!')
      expect(account).not_to be_valid
    end
  end

  describe 'settings' do
    it 'stores and retrieves settings as JSON' do
      account = create(:account, settings: { timezone: 'UTC', locale: 'en' })
      account.reload
      expect(account.settings['timezone']).to eq('UTC')
      expect(account.settings['locale']).to eq('en')
    end
  end

  describe 'subscription status' do
    it 'defaults to trialing for new accounts' do
      account = create(:account)
      expect(account.subscription_status).to eq('trialing')
    end

    it 'sets trial_ends_at to 14 days from creation' do
      account = create(:account)
      expect(account.trial_ends_at).to be_within(1.second).of(14.days.from_now)
    end
  end

  describe '#trial_expired?' do
    it 'returns true when trial has ended' do
      account = create(:account, trial_ends_at: 1.day.ago)
      expect(account.trial_expired?).to be true
    end

    it 'returns false when trial is active' do
      account = create(:account, trial_ends_at: 1.day.from_now)
      expect(account.trial_expired?).to be false
    end
  end

  describe '#active?' do
    it 'returns true for active subscriptions' do
      account = create(:account, subscription_status: 'active')
      expect(account.active?).to be true
    end

    it 'returns true for trialing accounts within trial period' do
      account = create(:account, subscription_status: 'trialing', trial_ends_at: 1.day.from_now)
      expect(account.active?).to be true
    end

    it 'returns false for expired trials' do
      account = create(:account, subscription_status: 'trialing', trial_ends_at: 1.day.ago)
      expect(account.active?).to be false
    end

    it 'returns false for canceled subscriptions' do
      account = create(:account, subscription_status: 'canceled')
      expect(account.active?).to be false
    end
  end
end
