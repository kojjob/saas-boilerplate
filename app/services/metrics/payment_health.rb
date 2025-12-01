# frozen_string_literal: true

module Metrics
  class PaymentHealth
    # Count of accounts with past due status
    def past_due_accounts_count
      Account.where(subscription_status: "past_due").count
    end

    # Percentage of accounts that are past due
    def past_due_percentage
      total = Account.where.not(subscription_status: %w[canceled none]).count
      return 0.0 if total.zero?

      ((past_due_accounts_count.to_f / total) * 100).round(2)
    end

    # MRR at risk from past due accounts
    def at_risk_revenue
      Account
        .where(subscription_status: "past_due")
        .joins(:plan)
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    # Failed payment rate (based on past_due / total active attempts)
    def failed_payment_rate
      total_active = Account.where(subscription_status: %w[active past_due]).count
      return 0.0 if total_active.zero?

      ((past_due_accounts_count.to_f / total_active) * 100).round(2)
    end

    # Recovery rate (accounts that moved from past_due to active)
    # This is a simplified version - would need payment history tracking for accurate calculation
    def recovery_rate
      # In a real implementation, this would track accounts that were past_due
      # and successfully recovered their payments
      # For now, return a placeholder
      0.0
    end

    # Accounts with failed payments grouped by age
    def past_due_by_age
      past_due_accounts = Account.where(subscription_status: "past_due")

      {
        "1-7 days" => past_due_accounts.where("updated_at >= ?", 7.days.ago).count,
        "8-14 days" => past_due_accounts.where("updated_at < ? AND updated_at >= ?", 7.days.ago, 14.days.ago).count,
        "15-30 days" => past_due_accounts.where("updated_at < ? AND updated_at >= ?", 14.days.ago, 30.days.ago).count,
        "30+ days" => past_due_accounts.where("updated_at < ?", 30.days.ago).count
      }
    end

    # Total MRR from healthy accounts
    def healthy_mrr
      Account
        .where(subscription_status: "active")
        .joins(:plan)
        .includes(:plan)
        .sum { |account| monthly_amount(account.plan) }
        .round(2)
    end

    # Revenue health score (0-100)
    def revenue_health_score
      total_mrr = MrrCalculator.new.mrr
      return 100.0 if total_mrr.zero?

      healthy_percentage = ((healthy_mrr / total_mrr) * 100).round(2)
      [healthy_percentage, 100.0].min
    end

    # Accounts needing dunning attention
    def accounts_needing_attention
      Account
        .where(subscription_status: "past_due")
        .where("updated_at < ?", 3.days.ago)
        .count
    end

    # Expected churn from past due (based on industry averages)
    # Typically 15-20% of past due accounts eventually churn
    def projected_churn_from_past_due
      (at_risk_revenue * 0.15).round(2)
    end

    private

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
