# frozen_string_literal: true

class RegistrationsController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain
  before_action :redirect_if_signed_in, only: [:new, :create]

  def new
    @user = User.new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)
    @user = User.new(user_params)

    ActiveRecord::Base.transaction do
      @account.save!
      @user.save!
      Membership.create!(user: @user, account: @account, role: 'owner')
      sign_in(@user)
    end

    redirect_to dashboard_path, notice: 'Welcome! Your account has been created.'
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def account_params
    params.require(:account).permit(:name)
  end

  def redirect_if_signed_in
    redirect_to dashboard_path, notice: 'You are already signed in.' if signed_in?
  end
end
