# frozen_string_literal: true

module Admin
  class AccountsController < BaseController
    include Pagy::Backend

    before_action :set_account, only: [ :show, :edit, :update, :destroy, :upgrade, :extend_trial ]

    def index
      accounts = Account.kept.includes(:plan, :memberships).order(created_at: :desc)
      accounts = accounts.where(subscription_status: params[:status]) if params[:status].present?
      @pagy, @accounts = pagy(accounts, limit: 25)
    end

    def show
    end

    def edit
    end

    def update
      if @account.update(account_params)
        redirect_to admin_account_path(@account), notice: "Account was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @account.discard
      redirect_to admin_accounts_path, notice: "Account was successfully deleted."
    end

    def upgrade
      plan = Plan.find(params[:plan_id])
      @account.update!(plan: plan)
      redirect_to admin_account_path(@account), notice: "Account was upgraded to #{plan.name}."
    end

    def extend_trial
      days = params[:days].to_i
      new_trial_end = (@account.trial_ends_at || Time.current) + days.days
      @account.update!(trial_ends_at: new_trial_end)
      redirect_to admin_account_path(@account), notice: "Trial extended by #{days} days."
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :subscription_status, :plan_id)
    end
  end
end
