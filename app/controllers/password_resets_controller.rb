# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain
  before_action :redirect_if_signed_in
  before_action :find_user_by_token, only: [:edit, :update]
  before_action :check_token_expiration, only: [:edit, :update]

  def new
  end

  def create
    if params[:email].blank?
      flash.now[:alert] = 'Please enter your email address.'
      render :new, status: :unprocessable_content
      return
    end

    user = User.find_by(email: params[:email].downcase.strip)

    if user
      user.generate_password_reset_token!
      PasswordResetMailer.reset_email(user).deliver_later
    end

    # Always redirect with success message to prevent email enumeration
    redirect_to sign_in_path, notice: 'If an account exists with that email, you will receive password reset instructions shortly.'
  end

  def edit
  end

  def update
    if params[:password].blank?
      flash.now[:alert] = 'Password cannot be blank.'
      render :edit, status: :unprocessable_content
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = 'Password confirmation does not match.'
      render :edit, status: :unprocessable_content
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset_token!
      redirect_to sign_in_path, notice: 'Your password has been reset successfully. Please sign in with your new password.'
    else
      flash.now[:alert] = @user.errors.full_messages.join(', ')
      render :edit, status: :unprocessable_content
    end
  end

  private

  def find_user_by_token
    @user = User.find_by(reset_password_token: params[:token])

    unless @user
      redirect_to new_password_reset_path, alert: 'Password reset link is invalid. Please request a new one.'
    end
  end

  def check_token_expiration
    return unless @user

    if @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: 'Password reset link has expired. Please request a new one.'
    end
  end

  def redirect_if_signed_in
    redirect_to dashboard_path, notice: 'You are already signed in.' if signed_in?
  end
end
