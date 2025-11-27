# frozen_string_literal: true

class ConfirmationsController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain
  before_action :redirect_if_signed_in, only: [:new]

  # GET /confirm_email/:token
  def show
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      redirect_to sign_in_path, alert: 'Confirmation link is invalid.'
      return
    end

    if @user.confirmed?
      redirect_path = signed_in? ? dashboard_path : sign_in_path
      redirect_to redirect_path, notice: 'Your email has already been confirmed.'
      return
    end

    @user.confirm!
    redirect_path = signed_in? ? dashboard_path : sign_in_path
    redirect_to redirect_path, notice: 'Your email has been confirmed. You can now sign in.'
  end

  # GET /confirmations/new (resend form)
  def new
  end

  # POST /confirmations (resend confirmation)
  def create
    if params[:email].blank?
      flash.now[:alert] = 'Please enter your email address.'
      render :new, status: :unprocessable_content
      return
    end

    user = User.find_by(email: params[:email].downcase.strip)

    if user && !user.confirmed?
      user.regenerate_confirmation_token!
      ConfirmationMailer.confirmation_email(user).deliver_later
    end

    # Always show success message to prevent email enumeration
    redirect_to sign_in_path, notice: 'If an account exists with that email, you will receive confirmation instructions shortly.'
  end

  private

  def redirect_if_signed_in
    redirect_to dashboard_path, notice: 'You are already signed in.' if signed_in?
  end
end
