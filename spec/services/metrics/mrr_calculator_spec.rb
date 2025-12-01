# frozen_string_literal: true

require "rails_helper"

RSpec.describe Metrics::MrrCalculator, type: :service do
  let(:free_plan) { create(:plan, name: "Free", price_cents: 0, interval: "month") }
  let(:basic_plan) { create(:plan, name: "Basic", price_cents: 2900, interval: "month") }
  let(:pro_plan) { create(:plan, name: "Pro", price_cents: 4900, interval: "month") }
  let(:annual_plan) { create(:plan, name: "Annual", price_cents: 49000, interval: "year") }

  subject(:calculator) { described_class.new }

  describe "#mrr" do
    context "with no accounts" do
      it "returns 0" do
        expect(calculator.mrr).to eq(0.0)
      end
    end

    context "with active monthly accounts" do
      before do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      end

      it "calculates MRR correctly" do
        # 3 accounts * $49/month = $147
        expect(calculator.mrr).to eq(147.0)
      end
    end

    context "with active annual accounts" do
      before do
        create_list(:account, 2, subscription_status: "active", plan: annual_plan)
      end

      it "converts annual to monthly" do
        # 2 accounts * ($490/year / 12 months) = $81.67
        expect(calculator.mrr).to be_within(0.01).of(81.67)
      end
    end

    context "with mixed subscription statuses" do
      before do
        create(:account, subscription_status: "active", plan: pro_plan)
        create(:account, subscription_status: "trialing", plan: basic_plan)
        create(:account, subscription_status: "canceled", plan: pro_plan)
        create(:account, subscription_status: "past_due", plan: basic_plan)
      end

      it "only includes active and trialing accounts" do
        # Only active ($49) + trialing ($29) = $78
        expect(calculator.mrr).to eq(78.0)
      end
    end

    context "with free plan accounts" do
      before do
        create(:account, subscription_status: "active", plan: free_plan)
        create(:account, subscription_status: "active", plan: pro_plan)
      end

      it "excludes free plans" do
        expect(calculator.mrr).to eq(49.0)
      end
    end
  end

  describe "#arr" do
    before do
      create(:account, subscription_status: "active", plan: pro_plan)
    end

    it "calculates ARR as MRR * 12" do
      expect(calculator.arr).to eq(588.0)
    end
  end

  describe "#mrr_by_plan" do
    before do
      create_list(:account, 2, subscription_status: "active", plan: basic_plan)
      create_list(:account, 3, subscription_status: "active", plan: pro_plan)
    end

    it "returns MRR breakdown by plan name" do
      result = calculator.mrr_by_plan

      expect(result["Basic"]).to eq(58.0)
      expect(result["Pro"]).to eq(147.0)
    end
  end

  describe "#new_mrr" do
    context "with new accounts within period" do
      before do
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 10.days.ago)
        create(:account, subscription_status: "active", plan: basic_plan, created_at: 45.days.ago)
      end

      it "only includes accounts created within the period" do
        expect(calculator.new_mrr(period: 30.days)).to eq(49.0)
      end
    end
  end

  describe "#churned_mrr" do
    context "with churned accounts" do
      before do
        create(:account, subscription_status: "canceled", plan: pro_plan,
               created_at: 60.days.ago, updated_at: 10.days.ago)
        create(:account, subscription_status: "canceled", plan: basic_plan,
               created_at: 60.days.ago, updated_at: 45.days.ago)
      end

      it "only includes accounts churned within the period" do
        expect(calculator.churned_mrr(period: 30.days)).to eq(49.0)
      end
    end

    context "with newly created and canceled accounts" do
      before do
        # This account was created and canceled within the same period
        create(:account, subscription_status: "canceled", plan: pro_plan,
               created_at: 10.days.ago, updated_at: 5.days.ago)
      end

      it "excludes accounts that didn't exist before the period" do
        expect(calculator.churned_mrr(period: 30.days)).to eq(0.0)
      end
    end
  end

  describe "#net_mrr_movement" do
    before do
      # New MRR: $49
      create(:account, subscription_status: "active", plan: pro_plan, created_at: 10.days.ago)
      # Churned MRR: $29
      create(:account, subscription_status: "canceled", plan: basic_plan,
             created_at: 60.days.ago, updated_at: 10.days.ago)
    end

    it "calculates net MRR movement" do
      # New MRR ($49) - Churned MRR ($29) = $20
      expect(calculator.net_mrr_movement).to eq(20.0)
    end
  end

  describe "#mrr_growth_rate" do
    context "with growth" do
      before do
        # Old account (exists before period)
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
        # New account (within period)
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 10.days.ago)
      end

      it "calculates growth rate as percentage" do
        # Previous MRR: $49, Current MRR: $98
        # Growth: ((98 - 49) / 49) * 100 = 100%
        expect(calculator.mrr_growth_rate).to eq(100.0)
      end
    end

    context "with no previous MRR" do
      before do
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 10.days.ago)
      end

      it "returns 0 to avoid division by zero" do
        expect(calculator.mrr_growth_rate).to eq(0.0)
      end
    end
  end

  describe "#mrr_at" do
    before do
      create(:account, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
      create(:account, subscription_status: "active", plan: basic_plan, created_at: 10.days.ago)
    end

    it "calculates MRR at a specific point in time" do
      # Only the first account existed 30 days ago
      expect(calculator.mrr_at(30.days.ago)).to eq(49.0)
    end
  end
end
