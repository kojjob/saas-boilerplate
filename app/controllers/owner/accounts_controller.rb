# frozen_string_literal: true

module Owner
  class AccountsController < BaseController
    include Pagy::Backend

    def index
      accounts = Account.includes(:plan, :users).order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present?
        accounts = accounts.where(subscription_status: params[:status])
      end

      # Filter by plan if provided
      if params[:plan_id].present?
        accounts = accounts.where(plan_id: params[:plan_id])
      end

      # Search by name or slug
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        accounts = accounts.where("name ILIKE ? OR slug ILIKE ?", search_term, search_term)
      end

      @pagy, @accounts = pagy(accounts, limit: 25)
      @plans = Plan.active.order(:sort_order)
      @statuses = Account.distinct.pluck(:subscription_status).compact
    end

    def show
      @account = Account.includes(:plan, :users, :memberships).find(params[:id])
      @owner = @account.memberships.find_by(role: :owner)&.user
      @members_count = @account.memberships.count
      @recent_activity = if @account.respond_to?(:audits)
        @account.audits.order(created_at: :desc).limit(10)
      else
        []
      end
    end
  end
end
