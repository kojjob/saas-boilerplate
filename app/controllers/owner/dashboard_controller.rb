# frozen_string_literal: true

module Owner
  class DashboardController < BaseController
    def index
      @mrr_calculator = ::Metrics::MrrCalculator.new
      @customer_analytics = ::Metrics::CustomerAnalytics.new
      @payment_health = ::Metrics::PaymentHealth.new

      # MRR metrics
      @mrr = @mrr_calculator.mrr
      @arr = @mrr_calculator.arr
      @mrr_by_plan = @mrr_calculator.mrr_by_plan
      @mrr_growth_rate = @mrr_calculator.mrr_growth_rate
      @net_mrr_movement = @mrr_calculator.net_mrr_movement

      # Customer metrics
      @total_customers = @customer_analytics.total_customers
      @active_customers = @customer_analytics.active_customers
      @customers_by_status = @customer_analytics.customers_by_status
      @churn_rate = @customer_analytics.churn_rate
      @ltv = @customer_analytics.ltv
      @arpu = @customer_analytics.arpu
      @trial_conversion_rate = @customer_analytics.trial_conversion_rate
      @net_customer_growth = @customer_analytics.net_customer_growth

      # Payment health
      @past_due_accounts_count = @payment_health.past_due_accounts_count
      @past_due_percentage = @payment_health.past_due_percentage
      @at_risk_revenue = @payment_health.at_risk_revenue
      @failed_payment_rate = @payment_health.failed_payment_rate
      @recovery_rate = @payment_health.recovery_rate
    end

    def metrics
      mrr_calculator = ::Metrics::MrrCalculator.new
      customer_analytics = ::Metrics::CustomerAnalytics.new
      payment_health = ::Metrics::PaymentHealth.new

      respond_to do |format|
        format.json do
          render json: {
            mrr: mrr_calculator.mrr,
            arr: mrr_calculator.arr,
            mrr_by_plan: mrr_calculator.mrr_by_plan,
            mrr_growth_rate: mrr_calculator.mrr_growth_rate,
            net_mrr_movement: mrr_calculator.net_mrr_movement,
            total_customers: customer_analytics.total_customers,
            active_customers: customer_analytics.active_customers,
            customers_by_status: customer_analytics.customers_by_status,
            churn_rate: customer_analytics.churn_rate,
            ltv: customer_analytics.ltv,
            arpu: customer_analytics.arpu,
            trial_conversion_rate: customer_analytics.trial_conversion_rate,
            net_customer_growth: customer_analytics.net_customer_growth,
            past_due_accounts_count: payment_health.past_due_accounts_count,
            past_due_percentage: payment_health.past_due_percentage,
            at_risk_revenue: payment_health.at_risk_revenue,
            failed_payment_rate: payment_health.failed_payment_rate,
            recovery_rate: payment_health.recovery_rate
          }
        end
      end
    end
  end
end
