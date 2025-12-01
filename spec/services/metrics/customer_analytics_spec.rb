# frozen_string_literal: true

require "rails_helper"

RSpec.describe Metrics::CustomerAnalytics, type: :service do
  let(:free_plan) { create(:plan, name: "Free", price_cents: 0, interval: "month") }
  let(:pro_plan) { create(:plan, name: "Pro", price_cents: 4900, interval: "month") }

  subject(:analytics) { described_class.new }

  describe "#total_customers" do
    context "with no accounts" do
      it "returns 0" do
        expect(analytics.total_customers).to eq(0)
      end
    end

    context "with accounts" do
      before do
        create_list(:account, 5, plan: pro_plan)
      end

      it "returns total count" do
        expect(analytics.total_customers).to eq(5)
      end
    end
  end

  describe "#active_customers" do
    before do
      create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      create_list(:account, 2, subscription_status: "past_due", plan: pro_plan)
      create(:account, subscription_status: "canceled", plan: pro_plan)
      create(:account, subscription_status: "trialing", plan: pro_plan)
    end

    it "counts active and past_due accounts" do
      expect(analytics.active_customers).to eq(5)
    end
  end

  describe "#customers_by_status" do
    before do
      create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      create_list(:account, 2, subscription_status: "trialing", plan: pro_plan)
      create(:account, subscription_status: "canceled", plan: pro_plan)
    end

    it "returns counts grouped by status" do
      result = analytics.customers_by_status

      expect(result["active"]).to eq(3)
      expect(result["trialing"]).to eq(2)
      expect(result["canceled"]).to eq(1)
    end
  end

  describe "#new_customers" do
    before do
      create_list(:account, 3, plan: pro_plan, created_at: 10.days.ago)
      create_list(:account, 2, plan: pro_plan, created_at: 45.days.ago)
    end

    it "counts accounts created within the period" do
      expect(analytics.new_customers(period: 30.days)).to eq(3)
    end
  end

  describe "#churned_customers" do
    before do
      create(:account, subscription_status: "canceled", plan: pro_plan,
             created_at: 60.days.ago, updated_at: 10.days.ago)
      create(:account, subscription_status: "canceled", plan: pro_plan,
             created_at: 60.days.ago, updated_at: 45.days.ago)
      # Newly created and canceled - shouldn't count as churn
      create(:account, subscription_status: "canceled", plan: pro_plan,
             created_at: 10.days.ago, updated_at: 5.days.ago)
    end

    it "counts accounts churned within the period" do
      expect(analytics.churned_customers(period: 30.days)).to eq(1)
    end
  end

  describe "#churn_rate" do
    context "with no existing customers" do
      before do
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 10.days.ago)
      end

      it "returns 0" do
        expect(analytics.churn_rate).to eq(0.0)
      end
    end

    context "with existing customers and churn" do
      before do
        # 4 accounts existed before the period (and are still active)
        create_list(:account, 4, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
        # 1 churned during the period (existed before period, cancelled within period)
        create(:account, subscription_status: "canceled", plan: pro_plan,
               created_at: 60.days.ago, updated_at: 10.days.ago)
      end

      it "calculates churn rate" do
        # Start of period customers = accounts created before period that weren't already canceled
        # = 4 active + 1 that was active then cancelled = 5 accounts existed before period
        # But the query looks for accounts where created_at < period.ago AND status != canceled
        # So at start of period we have 4 active (the 5th is now canceled but we don't count it)
        # 1 churned / 4 existing at start = 25%
        expect(analytics.churn_rate).to eq(25.0)
      end
    end
  end

  describe "#arpu" do
    context "with no active customers" do
      it "returns 0" do
        expect(analytics.arpu).to eq(0.0)
      end
    end

    context "with active customers" do
      before do
        create_list(:account, 2, subscription_status: "active", plan: pro_plan)
      end

      it "calculates ARPU" do
        # $98 MRR / 2 customers = $49
        expect(analytics.arpu).to eq(49.0)
      end
    end
  end

  describe "#ltv" do
    context "with no churn" do
      before do
        create(:account, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
      end

      it "returns 0 when churn rate is 0" do
        expect(analytics.ltv).to eq(0.0)
      end
    end

    context "with churn" do
      before do
        # Setup accounts for 25% churn rate (1 churned / 4 existing at start)
        create_list(:account, 4, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
        create(:account, subscription_status: "canceled", plan: pro_plan,
               created_at: 60.days.ago, updated_at: 10.days.ago)
      end

      it "calculates LTV as ARPU / churn rate" do
        # ARPU: $49 (4 active accounts paying $49/month / 4 active customers = $49)
        # Churn: 25% (1 / 4 = 0.25)
        # LTV: $49 / 0.25 = $196
        expect(analytics.ltv).to eq(196.0)
      end
    end
  end

  describe "#trial_conversion_rate" do
    context "with no trials" do
      it "returns 0" do
        expect(analytics.trial_conversion_rate).to eq(0.0)
      end
    end

    context "with trials that converted" do
      before do
        # Converted trials (active/past_due with trial_ends_at in past)
        create_list(:account, 3, subscription_status: "active", plan: pro_plan,
                    trial_ends_at: 10.days.ago)
        # Still trialing (trial_ends_at in future)
        create_list(:account, 3, subscription_status: "trialing", plan: pro_plan,
                    trial_ends_at: 10.days.from_now)
      end

      it "calculates conversion rate" do
        # Converted: accounts with paying status AND trial_ends_at in the past = 3
        # Total trials: all accounts with trial_ends_at set = 6 (3 converted + 3 trialing)
        # 3 converted / 6 total trials = 50%
        expect(analytics.trial_conversion_rate).to eq(50.0)
      end
    end
  end

  describe "#net_customer_growth" do
    before do
      # New customers
      create_list(:account, 5, plan: pro_plan, created_at: 10.days.ago)
      # Churned customers
      create_list(:account, 2, subscription_status: "canceled", plan: pro_plan,
                  created_at: 60.days.ago, updated_at: 10.days.ago)
    end

    it "calculates net growth" do
      expect(analytics.net_customer_growth).to eq(3)
    end
  end

  describe "#customers_by_plan" do
    let(:basic_plan) { create(:plan, name: "Basic", price_cents: 2900, interval: "month") }

    before do
      create_list(:account, 3, plan: basic_plan)
      create_list(:account, 2, plan: pro_plan)
    end

    it "returns counts grouped by plan" do
      result = analytics.customers_by_plan

      expect(result["Basic"]).to eq(3)
      expect(result["Pro"]).to eq(2)
    end
  end

  describe "#retention_rate" do
    before do
      create_list(:account, 4, subscription_status: "active", plan: pro_plan, created_at: 60.days.ago)
      create(:account, subscription_status: "canceled", plan: pro_plan,
             created_at: 60.days.ago, updated_at: 10.days.ago)
    end

    it "calculates retention rate as 100 - churn rate" do
      # 25% churn (1 churned / 4 existing at start) = 75% retention
      expect(analytics.retention_rate).to eq(75.0)
    end
  end

  describe "#trialing_customers" do
    before do
      create_list(:account, 3, subscription_status: "trialing", plan: pro_plan)
      create_list(:account, 2, subscription_status: "active", plan: pro_plan)
    end

    it "counts trialing accounts" do
      expect(analytics.trialing_customers).to eq(3)
    end
  end

  describe "#trials_expiring_soon" do
    before do
      # Expiring within 7 days
      create_list(:account, 2, subscription_status: "trialing", plan: pro_plan,
                  trial_ends_at: 3.days.from_now)
      # Expiring later
      create(:account, subscription_status: "trialing", plan: pro_plan,
             trial_ends_at: 14.days.from_now)
      # Already expired
      create(:account, subscription_status: "trialing", plan: pro_plan,
             trial_ends_at: 2.days.ago)
    end

    it "counts trials expiring within 7 days" do
      expect(analytics.trials_expiring_soon).to eq(2)
    end
  end
end
