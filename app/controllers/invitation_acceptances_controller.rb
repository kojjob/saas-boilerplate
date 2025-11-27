# frozen_string_literal: true

class InvitationAcceptancesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :create], raise: false
  before_action :set_membership
  before_action :validate_invitation
  before_action :check_email_match, if: :signed_in?

  def show
    @account = @membership.account
    @existing_user = User.find_by(email: @membership.invitation_email)
  end

  def create
    @account = @membership.account
    @existing_user = User.find_by(email: @membership.invitation_email)

    if @existing_user
      # Existing user - just accept the invitation
      @membership.accept_invitation!(@existing_user)

      # Sign them in if not already
      sign_in(@existing_user) unless signed_in?
      set_tenant_for_user(@existing_user, @account)

      redirect_to dashboard_path, notice: "Welcome to #{@account.name}!"
    else
      # New user - create account and accept invitation
      @user = User.new(user_params)
      @user.email = @membership.invitation_email
      @user.confirmed_at = Time.current # Auto-confirm since they received the email

      if @user.save
        @membership.accept_invitation!(@user)

        # Sign them in
        sign_in(@user)
        set_tenant_for_user(@user, @account)

        redirect_to dashboard_path, notice: "Welcome to #{@account.name}!"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def set_membership
    @membership = Membership.find_by(invitation_token: params[:token])
  end

  def validate_invitation
    if @membership.nil?
      redirect_to sign_in_path, alert: 'This invitation is invalid or has already been used.'
      return
    end

    if @membership.invitation_expired?
      redirect_to sign_in_path, alert: 'This invitation has expired. Please request a new one.'
    end
  end

  def check_email_match
    return unless @membership

    if current_user.email != @membership.invitation_email
      redirect_to dashboard_path, alert: 'This invitation was sent to a different email address. Please sign in with the correct account.'
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end
end
