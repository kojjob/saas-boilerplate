# frozen_string_literal: true

require "rails_helper"

RSpec.describe Metrics::PaymentHealth, type: :service do
  let(:pro_plan) { create(:plan, name: "Pro", price_cents: 4900, interval: "month") }
  let(:basic_plan) { create(:plan, name: "Basic", price_cents: 2900, interval: "month") }

  subject(:health) { described_class.new }

  describe "#past_due_accounts_count" do
    context "with no past due accounts" do
      before do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      end

      it "returns 0" do
        expect(health.past_due_accounts_count).to eq(0)
      end
    end

    context "with past due accounts" do
      before do
        create_list(:account, 3, subscription_status: "past_due", plan: pro_plan)
        create_list(:account, 2, subscription_status: "active", plan: pro_plan)
      end

      it "returns count of past due accounts" do
        expect(health.past_due_accounts_count).to eq(3)
      end
    end
  end

  describe "#past_due_percentage" do
    context "with no active accounts" do
      it "returns 0" do
        expect(health.past_due_percentage).to eq(0.0)
      end
    end

    context "with active and past due accounts" do
      before do
        create_list(:account, 4, subscription_status: "active", plan: pro_plan)
        create(:account, subscription_status: "past_due", plan: pro_plan)
      end

      it "calculates percentage" do
        # 1 past due / 5 total = 20%
        expect(health.past_due_percentage).to eq(20.0)
      end
    end

    context "excludes canceled accounts from total" do
      before do
        create_list(:account, 4, subscription_status: "active", plan: pro_plan)
        create(:account, subscription_status: "past_due", plan: pro_plan)
        create_list(:account, 2, subscription_status: "canceled", plan: pro_plan)
      end

      it "excludes canceled from total" do
        # 1 past due / 5 active (not counting 2 canceled) = 20%
        expect(health.past_due_percentage).to eq(20.0)
      end
    end
  end

  describe "#at_risk_revenue" do
    context "with no past due accounts" do
      before do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      end

      it "returns 0" do
        expect(health.at_risk_revenue).to eq(0.0)
      end
    end

    context "with past due accounts" do
      before do
        create_list(:account, 2, subscription_status: "past_due", plan: pro_plan)
        create(:account, subscription_status: "past_due", plan: basic_plan)
      end

      it "calculates MRR at risk" do
        # 2 * $49 + 1 * $29 = $127
        expect(health.at_risk_revenue).to eq(127.0)
      end
    end
  end

  describe "#failed_payment_rate" do
    context "with no active accounts" do
      it "returns 0" do
        expect(health.failed_payment_rate).to eq(0.0)
      end
    end

    context "with active and past due accounts" do
      before do
        create_list(:account, 4, subscription_status: "active", plan: pro_plan)
        create(:account, subscription_status: "past_due", plan: pro_plan)
      end

      it "calculates failure rate" do
        # 1 past due / 5 total active/past_due = 20%
        expect(health.failed_payment_rate).to eq(20.0)
      end
    end
  end

  describe "#recovery_rate" do
    it "returns 0 (placeholder)" do
      expect(health.recovery_rate).to eq(0.0)
    end
  end

  describe "#past_due_by_age" do
    before do
      create(:account, subscription_status: "past_due", plan: pro_plan, updated_at: 3.days.ago)
      create(:account, subscription_status: "past_due", plan: pro_plan, updated_at: 10.days.ago)
      create(:account, subscription_status: "past_due", plan: pro_plan, updated_at: 20.days.ago)
      create(:account, subscription_status: "past_due", plan: pro_plan, updated_at: 45.days.ago)
    end

    it "groups past due accounts by age" do
      result = health.past_due_by_age

      expect(result["1-7 days"]).to eq(1)
      expect(result["8-14 days"]).to eq(1)
      expect(result["15-30 days"]).to eq(1)
      expect(result["30+ days"]).to eq(1)
    end
  end

  describe "#healthy_mrr" do
    before do
      create_list(:account, 2, subscription_status: "active", plan: pro_plan)
      create(:account, subscription_status: "past_due", plan: pro_plan)
      create(:account, subscription_status: "trialing", plan: pro_plan)
    end

    it "only includes active accounts" do
      # 2 * $49 = $98
      expect(health.healthy_mrr).to eq(98.0)
    end
  end

  describe "#revenue_health_score" do
    context "with no MRR" do
      it "returns 100" do
        expect(health.revenue_health_score).to eq(100.0)
      end
    end

    context "with all healthy accounts" do
      before do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)
      end

      it "returns 100" do
        expect(health.revenue_health_score).to eq(100.0)
      end
    end

    context "with some past due accounts" do
      before do
        create_list(:account, 3, subscription_status: "active", plan: pro_plan)
        create(:account, subscription_status: "trialing", plan: pro_plan)
      end

      it "calculates health score" do
        # Healthy MRR: $147, Total MRR: $196
        # Score: ($147 / $196) * 100 = 75%
        expect(health.revenue_health_score).to eq(75.0)
      end
    end
  end

  describe "#accounts_needing_attention" do
    before do
      # Needing attention (past due for more than 3 days)
      create_list(:account, 2, subscription_status: "past_due", plan: pro_plan, updated_at: 5.days.ago)
      # Not needing attention yet
      create(:account, subscription_status: "past_due", plan: pro_plan, updated_at: 1.day.ago)
    end

    it "counts accounts past due for more than 3 days" do
      expect(health.accounts_needing_attention).to eq(2)
    end
  end

  describe "#projected_churn_from_past_due" do
    before do
      create_list(:account, 2, subscription_status: "past_due", plan: pro_plan)
    end

    it "estimates 15% of at-risk revenue will churn" do
      # At-risk: $98, Projected churn: $98 * 0.15 = $14.70
      expect(health.projected_churn_from_past_due).to eq(14.7)
    end
  end
end
