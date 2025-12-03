# frozen_string_literal: true

module Owner
  class ReportsController < BaseController
    def index
      @mrr_calculator = ::Metrics::MrrCalculator.new
      @customer_analytics = ::Metrics::CustomerAnalytics.new
      @payment_health = ::Metrics::PaymentHealth.new
    end

    def show
      @report_type = params[:id]
      case @report_type
      when "mrr"
        redirect_to mrr_owner_reports_path
      when "customers"
        redirect_to customers_owner_reports_path
      when "payments"
        redirect_to payments_owner_reports_path
      else
        redirect_to owner_reports_path, alert: "Unknown report type"
      end
    end

    def mrr
      @mrr_calculator = ::Metrics::MrrCalculator.new
      @mrr = @mrr_calculator.mrr
      @arr = @mrr_calculator.arr
      @mrr_by_plan = @mrr_calculator.mrr_by_plan
      @mrr_growth_rate = @mrr_calculator.mrr_growth_rate
      @net_mrr_movement = @mrr_calculator.net_mrr_movement
    end

    def customers
      @customer_analytics = ::Metrics::CustomerAnalytics.new
      @total_customers = @customer_analytics.total_customers
      @active_customers = @customer_analytics.active_customers
      @customers_by_status = @customer_analytics.customers_by_status
      @churn_rate = @customer_analytics.churn_rate
      @ltv = @customer_analytics.ltv
      @arpu = @customer_analytics.arpu
      @trial_conversion_rate = @customer_analytics.trial_conversion_rate
      @net_customer_growth = @customer_analytics.net_customer_growth
      @new_customers = @customer_analytics.new_customers
      @churned_customers = @customer_analytics.churned_customers
      @retention_rate = @customer_analytics.retention_rate
      @average_customer_age = @customer_analytics.average_customer_age
      @trialing_customers = @customer_analytics.trialing_customers
      @trials_expiring_soon = @customer_analytics.trials_expiring_soon
      @customers_by_plan = @customer_analytics.customers_by_plan
    end

    def payments
      @payment_health = ::Metrics::PaymentHealth.new
      @past_due_accounts_count = @payment_health.past_due_accounts_count
      @past_due_percentage = @payment_health.past_due_percentage
      @at_risk_revenue = @payment_health.at_risk_revenue
      @failed_payment_rate = @payment_health.failed_payment_rate
      @recovery_rate = @payment_health.recovery_rate
      @past_due_by_age = @payment_health.past_due_by_age
      @healthy_mrr = @payment_health.healthy_mrr
      @revenue_health_score = @payment_health.revenue_health_score
      @accounts_needing_attention = @payment_health.accounts_needing_attention
      @projected_churn_from_past_due = @payment_health.projected_churn_from_past_due
      @total_active_accounts = Account.where(subscription_status: %w[active past_due]).count
    end
  end
end
