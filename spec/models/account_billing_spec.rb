# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, "billing", type: :model do
  let(:account) { create(:account) }

  describe 'Pay::Billable' do
    it 'includes Pay attributes for billing' do
      # Pay gem 8.x uses Pay::Attributes::CustomerExtension instead of Pay::Billable
      expect(Account.ancestors).to include(Pay::Attributes::CustomerExtension)
    end

    it 'responds to pay_customer methods' do
      expect(account).to respond_to(:payment_processor)
      expect(account).to respond_to(:pay_customers)
    end
  end

  describe '#set_payment_processor' do
    it 'creates a Stripe payment processor', :vcr do
      account.set_payment_processor(:stripe)
      expect(account.payment_processor).to be_present
      expect(account.payment_processor.processor).to eq('stripe')
    end
  end

  describe '#current_plan' do
    let!(:free_plan) { create(:plan, :free) }
    let!(:pro_plan) { create(:plan, :pro) }

    context 'when account has no subscription' do
      it 'returns the free plan if available' do
        expect(account.current_plan).to eq(free_plan)
      end
    end

    context 'when account has an active subscription' do
      before do
        account.update!(plan: pro_plan)
      end

      it 'returns the subscribed plan' do
        expect(account.current_plan).to eq(pro_plan)
      end
    end
  end

  describe '#subscribed?' do
    let!(:pro_plan) { create(:plan, :pro) }

    it 'returns false when no plan is set' do
      expect(account.subscribed?).to be false
    end

    it 'returns true when plan is set and subscription is active' do
      account.update!(plan: pro_plan, subscription_status: 'active')
      expect(account.subscribed?).to be true
    end

    it 'returns true during trial period' do
      account.update!(plan: pro_plan, subscription_status: 'trialing')
      expect(account.subscribed?).to be true
    end

    it 'returns false when subscription is canceled' do
      account.update!(plan: pro_plan, subscription_status: 'canceled')
      expect(account.subscribed?).to be false
    end
  end

  describe '#on_trial?' do
    it 'returns true when status is trialing and trial not expired' do
      account.update!(
        subscription_status: 'trialing',
        trial_ends_at: 7.days.from_now
      )
      expect(account.on_trial?).to be true
    end

    it 'returns false when trial has expired' do
      account.update!(
        subscription_status: 'trialing',
        trial_ends_at: 1.day.ago
      )
      expect(account.on_trial?).to be false
    end

    it 'returns false when not on trial' do
      account.update!(subscription_status: 'active')
      expect(account.on_trial?).to be false
    end
  end

  describe '#can_access_feature?' do
    let(:pro_plan) { create(:plan, :pro, features: ['advanced_reports', 'api_access']) }

    before do
      account.update!(plan: pro_plan, subscription_status: 'active')
    end

    it 'returns true for included features' do
      expect(account.can_access_feature?('advanced_reports')).to be true
      expect(account.can_access_feature?('api_access')).to be true
    end

    it 'returns false for non-included features' do
      expect(account.can_access_feature?('enterprise_feature')).to be false
    end
  end

  describe '#within_limit?' do
    let(:pro_plan) { create(:plan, :pro, limits: { 'users' => 25, 'projects' => 500 }) }

    before do
      account.update!(plan: pro_plan, subscription_status: 'active')
    end

    it 'returns true when within limits' do
      expect(account.within_limit?('users', 10)).to be true
      expect(account.within_limit?('projects', 100)).to be true
    end

    it 'returns false when at limit' do
      expect(account.within_limit?('users', 25)).to be false
    end

    it 'returns false when over limit' do
      expect(account.within_limit?('users', 30)).to be false
    end

    context 'with unlimited plan' do
      let(:enterprise_plan) { create(:plan, :enterprise, limits: { 'users' => -1 }) }

      before do
        account.update!(plan: enterprise_plan)
      end

      it 'returns true for unlimited resources' do
        expect(account.within_limit?('users', 1000)).to be true
      end
    end
  end

  describe '#billing_email' do
    let(:owner) { create(:user, email: 'owner@example.com') }
    let!(:membership) { create(:membership, user: owner, account: account, role: 'owner') }

    it 'returns the account owner email' do
      expect(account.billing_email).to eq('owner@example.com')
    end
  end
end
