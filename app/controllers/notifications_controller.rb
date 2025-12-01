# frozen_string_literal: true

class NotificationsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_notification, only: [ :show, :destroy ]

  def index
    @notifications = current_user.notifications.recent.limit(50)
  end

  def show
    @notification.mark_as_read! unless @notification.read_at.present?
  end

  def destroy
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "Notification deleted." }
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    @notifications = current_user.notifications.recent.limit(50)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      format.turbo_stream
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
