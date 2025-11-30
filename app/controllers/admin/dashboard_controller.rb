# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.kept.count
      @total_accounts = Account.kept.count
      @recent_users = User.kept.order(created_at: :desc).limit(5)
      @recent_accounts = Account.kept.includes(:plan, :memberships).order(created_at: :desc).limit(5)

      # Subscription statistics - single query with GROUP BY instead of 4 separate queries
      stats = Account.kept.group(:subscription_status).count
      @subscription_stats = {
        trialing: stats["trialing"] || 0,
        active: stats["active"] || 0,
        past_due: stats["past_due"] || 0,
        canceled: stats["canceled"] || 0
      }
    end
  end
end
