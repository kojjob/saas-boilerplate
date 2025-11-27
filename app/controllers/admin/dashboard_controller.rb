# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.kept.count
      @total_accounts = Account.kept.count
      @recent_users = User.kept.order(created_at: :desc).limit(5)
      @recent_accounts = Account.kept.order(created_at: :desc).limit(5)

      # Subscription statistics
      @subscription_stats = {
        trialing: Account.kept.where(subscription_status: "trialing").count,
        active: Account.kept.where(subscription_status: "active").count,
        past_due: Account.kept.where(subscription_status: "past_due").count,
        canceled: Account.kept.where(subscription_status: "canceled").count
      }
    end
  end
end
