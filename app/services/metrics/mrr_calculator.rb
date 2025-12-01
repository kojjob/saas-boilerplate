# frozen_string_literal: true

module Metrics
  class MrrCalculator
    ACTIVE_STATUSES = %w[active trialing].freeze

    # Calculate Monthly Recurring Revenue
    def mrr
      Account
        .where(subscription_status: ACTIVE_STATUSES)
        .joins(:plan)
        .where("plans.price_cents > 0")
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    # Calculate Annual Recurring Revenue
    def arr
      (mrr * 12).round(2)
    end

    # Calculate MRR breakdown by plan
    def mrr_by_plan
      Account
        .where(subscription_status: ACTIVE_STATUSES)
        .joins(:plan)
        .where("plans.price_cents > 0")
        .includes(:plan)
        .group_by { |account| account.plan.name }
        .transform_values { |accounts| accounts.sum { |a| monthly_amount(a.plan) }.round(2) }
    end

    # Calculate new MRR from new customers (last 30 days)
    def new_mrr(period: 30.days)
      Account
        .where(subscription_status: ACTIVE_STATUSES)
        .where("accounts.created_at >= ?", period.ago)
        .joins(:plan)
        .where("plans.price_cents > 0")
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    # Calculate churned MRR (last 30 days)
    def churned_mrr(period: 30.days)
      Account
        .where(subscription_status: "canceled")
        .where("accounts.updated_at >= ?", period.ago)
        .where("accounts.created_at < ?", period.ago) # Must have existed before period
        .joins(:plan)
        .where("plans.price_cents > 0")
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    # Calculate expansion MRR (upgrades in last 30 days)
    def expansion_mrr(period: 30.days)
      # This would require tracking plan changes - simplified version
      0.0
    end

    # Calculate contraction MRR (downgrades in last 30 days)
    def contraction_mrr(period: 30.days)
      # This would require tracking plan changes - simplified version
      0.0
    end

    # Net MRR movement = new + expansion - churned - contraction
    def net_mrr_movement(period: 30.days)
      (new_mrr(period: period) + expansion_mrr(period: period) -
        churned_mrr(period: period) - contraction_mrr(period: period)).round(2)
    end

    # MRR growth rate (percentage)
    def mrr_growth_rate(period: 30.days)
      previous_mrr = mrr_at(period.ago)
      current_mrr = mrr

      return 0.0 if previous_mrr.zero?

      (((current_mrr - previous_mrr) / previous_mrr) * 100).round(2)
    end

    # Calculate MRR at a specific point in time
    def mrr_at(date)
      Account
        .where(subscription_status: ACTIVE_STATUSES)
        .where("accounts.created_at <= ?", date)
        .joins(:plan)
        .where("plans.price_cents > 0")
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    private

    # Convert plan price to monthly amount
    def monthly_amount(plan)
      return 0.0 unless plan

      case plan.interval
      when "month"
        plan.price_cents / 100.0
      when "year"
        (plan.price_cents / 100.0) / 12.0
      else
        plan.price_cents / 100.0
      end
    end
  end
end
