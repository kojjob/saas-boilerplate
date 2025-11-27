# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'validations' do
    subject { build(:plan) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:stripe_price_id) }
    it { should validate_uniqueness_of(:stripe_price_id) }
    it { should validate_numericality_of(:price_cents).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:trial_days).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:active_plan) { create(:plan, active: true) }
    let!(:inactive_plan) { create(:plan, active: false) }
    let!(:free_plan) { create(:plan, price_cents: 0, active: true) }
    let!(:paid_plan) { create(:plan, price_cents: 999, active: true) }

    describe '.active' do
      it 'returns only active plans' do
        expect(Plan.active).to include(active_plan, free_plan, paid_plan)
        expect(Plan.active).not_to include(inactive_plan)
      end
    end

    describe '.paid' do
      it 'returns plans with price > 0' do
        expect(Plan.paid).to include(paid_plan, active_plan)
        expect(Plan.paid).not_to include(free_plan)
      end
    end

    describe '.free' do
      it 'returns plans with price = 0' do
        expect(Plan.free).to include(free_plan)
        expect(Plan.free).not_to include(paid_plan)
      end
    end
  end

  describe '#price' do
    it 'returns price in dollars' do
      plan = build(:plan, price_cents: 1999)
      expect(plan.price).to eq(19.99)
    end
  end

  describe '#free?' do
    it 'returns true for free plans' do
      plan = build(:plan, price_cents: 0)
      expect(plan.free?).to be true
    end

    it 'returns false for paid plans' do
      plan = build(:plan, price_cents: 999)
      expect(plan.free?).to be false
    end
  end

  describe '#formatted_price' do
    it 'returns formatted price string' do
      plan = build(:plan, price_cents: 1999)
      expect(plan.formatted_price).to eq('$19.99')
    end

    it 'returns Free for free plans' do
      plan = build(:plan, price_cents: 0)
      expect(plan.formatted_price).to eq('Free')
    end
  end

  describe '#interval_label' do
    it 'returns monthly for month interval' do
      plan = build(:plan, interval: 'month')
      expect(plan.interval_label).to eq('monthly')
    end

    it 'returns yearly for year interval' do
      plan = build(:plan, interval: 'year')
      expect(plan.interval_label).to eq('yearly')
    end
  end
end
