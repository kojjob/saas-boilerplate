# frozen_string_literal: true

module Metrics
  class CustomerAnalytics
    ACTIVE_STATUSES = %w[active trialing].freeze
    PAYING_STATUSES = %w[active past_due].freeze

    # Total number of accounts
    def total_customers
      Account.count
    end

    # Active paying customers
    def active_customers
      Account.where(subscription_status: PAYING_STATUSES).count
    end

    # Customers by subscription status
    def customers_by_status
      Account.group(:subscription_status).count
    end

    # New customers in a period
    def new_customers(period: 30.days)
      Account.where("created_at >= ?", period.ago).count
    end

    # Churned customers in a period
    def churned_customers(period: 30.days)
      Account
        .where(subscription_status: "canceled")
        .where("updated_at >= ?", period.ago)
        .where("created_at < ?", period.ago)
        .count
    end

    # Customer churn rate (percentage)
    def churn_rate(period: 30.days)
      start_of_period_customers = Account
        .where("created_at < ?", period.ago)
        .where.not(subscription_status: "canceled")
        .count

      return 0.0 if start_of_period_customers.zero?

      churned = churned_customers(period: period)
      ((churned.to_f / start_of_period_customers) * 100).round(2)
    end

    # Average Revenue Per User (ARPU)
    def arpu
      total_active = active_customers
      return 0.0 if total_active.zero?

      mrr_calculator = MrrCalculator.new
      (mrr_calculator.mrr / total_active).round(2)
    end

    # Customer Lifetime Value (LTV)
    # LTV = ARPU / Churn Rate (monthly)
    def ltv
      monthly_churn = churn_rate / 100.0
      return 0.0 if monthly_churn <= 0

      (arpu / monthly_churn).round(2)
    end

    # Trial to paid conversion rate
    def trial_conversion_rate
      # Count accounts that started as trial and converted to active
      converted = Account
        .where(subscription_status: PAYING_STATUSES)
        .where("trial_ends_at IS NOT NULL AND trial_ends_at < ?", Time.current)
        .count

      total_trials = Account
        .where("trial_ends_at IS NOT NULL")
        .count

      return 0.0 if total_trials.zero?

      ((converted.to_f / total_trials) * 100).round(2)
    end

    # Net customer growth (new - churned)
    def net_customer_growth(period: 30.days)
      new_customers(period: period) - churned_customers(period: period)
    end

    # Customers by plan
    def customers_by_plan
      Account
        .joins(:plan)
        .group("plans.name")
        .count
    end

    # Retention rate
    def retention_rate(period: 30.days)
      (100.0 - churn_rate(period: period)).round(2)
    end

    # Average customer age in days
    def average_customer_age
      avg_created_at = Account.average("EXTRACT(EPOCH FROM (NOW() - created_at))")
      return 0 if avg_created_at.nil?

      (avg_created_at / 86400).round(0) # Convert seconds to days
    end

    # Customers in trial
    def trialing_customers
      Account.where(subscription_status: "trialing").count
    end

    # Trials expiring soon (within 7 days)
    def trials_expiring_soon
      Account
        .where(subscription_status: "trialing")
        .where("trial_ends_at BETWEEN ? AND ?", Time.current, 7.days.from_now)
        .count
    end
  end
end
