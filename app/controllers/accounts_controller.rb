# frozen_string_literal: true

class AccountsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update, :billing]
  before_action :authorize_account, only: [:edit, :update]

  # GET /account
  def show
    @membership = current_user.memberships.find_by(account: @account)
  end

  # GET /account/edit
  def edit
  end

  # PATCH/PUT /account
  def update
    if @account.update(account_params)
      redirect_to account_path, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /account/billing
  def billing
    @plans = Plan.active.sorted
    @current_plan = @account.current_plan
  end

  # POST /account/switch
  def switch
    account = current_user.accounts.find_by(id: params[:account_id])

    if account
      session[:current_account_id] = account.id
      set_current_tenant(account)
      redirect_to dashboard_path, notice: "Switched to #{account.name}."
    else
      redirect_to account_path, alert: "You don't have access to that account."
    end
  end

  private

  def set_account
    @account = current_account || current_user.accounts.first

    unless @account
      redirect_to root_path, alert: "No account found. Please create an account first."
    end
  end

  def authorize_account
    membership = current_user.memberships.find_by(account: @account)

    unless membership&.can_manage_account?
      redirect_to account_path, alert: "You don't have permission to edit this account."
    end
  end

  def account_params
    params.require(:account).permit(:name, :subdomain)
  end
end
