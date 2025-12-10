# frozen_string_literal: true

class ProfilesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!

  # GET /profile/edit
  def edit
    @user = current_user
    @sessions = current_user.sessions.order(created_at: :desc).limit(10)
  end

  # PATCH /profile
  def update
    @user = current_user

    if @user.update(profile_params)
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Profile updated successfully." }
        format.turbo_stream do
          flash.now[:notice] = "Profile updated successfully."
          render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_content")
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          flash.now[:alert] = @user.errors.full_messages.join(", ")
          render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_content")
        end
      end
    end
  end

  # PATCH /profile/password
  def update_password
    @user = current_user

    unless @user.authenticate(params[:current_password])
      @user.errors.add(:current_password, "is incorrect")
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          flash.now[:alert] = "Current password is incorrect."
          render turbo_stream: turbo_stream.replace("password-form", partial: "profiles/password_form", locals: { user: @user })
        end
      end
      return
    end

    if @user.update(password_params)
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Password updated successfully." }
        format.turbo_stream do
          flash.now[:notice] = "Password updated successfully."
          render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_content")
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          flash.now[:alert] = @user.errors.full_messages.join(", ")
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "shared/flash_content"),
            turbo_stream.replace("password-form", partial: "profiles/password_form", locals: { user: @user })
          ]
        end
      end
    end
  end

  # PATCH /profile/avatar
  def update_avatar
    @user = current_user

    if params[:avatar].blank?
      respond_to do |format|
        format.html { redirect_to edit_profile_path, alert: "Please select an image to upload." }
        format.turbo_stream do
          flash.now[:alert] = "Please select an image to upload."
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "shared/flash_content"),
            turbo_stream.replace("avatar-section", partial: "profiles/avatar_section", locals: { user: @user })
          ]
        end
      end
      return
    end

    @user.avatar.attach(params[:avatar])

    if @user.avatar.attached? && @user.valid?
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Avatar updated successfully." }
        format.turbo_stream do
          flash.now[:notice] = "Avatar updated successfully."
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "shared/flash_content"),
            turbo_stream.replace("avatar-section", partial: "profiles/avatar_section", locals: { user: @user })
          ]
        end
      end
    else
      @user.avatar.purge if @user.avatar.attached?
      respond_to do |format|
        format.html { redirect_to edit_profile_path, alert: @user.errors.full_messages.join(", ") }
        format.turbo_stream do
          flash.now[:alert] = @user.errors.full_messages.join(", ")
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "shared/flash_content"),
            turbo_stream.replace("avatar-section", partial: "profiles/avatar_section", locals: { user: @user })
          ]
        end
      end
    end
  end

  # DELETE /profile/avatar
  def remove_avatar
    @user = current_user
    @user.avatar.purge if @user.avatar.attached?

    respond_to do |format|
      format.html { redirect_to edit_profile_path, notice: "Avatar removed successfully." }
      format.turbo_stream do
        flash.now[:notice] = "Avatar removed successfully."
        render turbo_stream: [
          turbo_stream.update("flash-messages", partial: "shared/flash_content"),
          turbo_stream.replace("avatar-section", partial: "profiles/avatar_section", locals: { user: @user })
        ]
      end
    end
  end

  # PATCH /profile/notifications
  def update_notifications
    @user = current_user

    if @user.update(notification_params)
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Notification preferences updated." }
        format.turbo_stream { flash.now[:notice] = "Notification preferences updated." }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { flash.now[:alert] = "Failed to update notification preferences." }
      end
    end
  end

  # DELETE /profile/sessions/:id
  def revoke_session
    session_to_revoke = current_user.sessions.find_by(id: params[:session_id])

    if session_to_revoke
      session_to_revoke.destroy
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Session revoked successfully." }
        format.turbo_stream { flash.now[:notice] = "Session revoked successfully." }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_profile_path, alert: "Session not found." }
        format.turbo_stream { flash.now[:alert] = "Session not found." }
      end
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :job_title, :time_zone, :locale)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def notification_params
    params.require(:user).permit(:email_notifications, :sms_notifications)
  end
end
