# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_notification, only: [:show, :mark_as_read, :destroy]

      def index
        @notifications = current_api_user.notifications.recent
        @notifications = @notifications.unread if params[:unread] == "true"

        render_success({ notifications: serialize_notifications(@notifications) })
      end

      def show
        render_success({ notification: serialize_notification(@notification) })
      end

      def mark_as_read
        @notification.mark_as_read!

        render_success({ notification: serialize_notification(@notification) })
      end

      def mark_all_as_read
        current_api_user.notifications.unread.update_all(read_at: Time.current)

        render_success({ message: "All notifications marked as read" })
      end

      def unread_count
        count = current_api_user.notifications.unread.count

        render_success({ unread_count: count })
      end

      def destroy
        @notification.destroy

        render_no_content
      end

      private

      def set_notification
        @notification = current_api_user.notifications.find(params[:id])
      end

      def serialize_notification(notification)
        {
          id: notification.id,
          title: notification.title,
          body: notification.body,
          notification_type: notification.notification_type,
          read_at: notification.read_at,
          created_at: notification.created_at,
          notifiable_type: notification.notifiable_type,
          notifiable_id: notification.notifiable_id
        }
      end

      def serialize_notifications(notifications)
        notifications.map { |n| serialize_notification(n) }
      end
    end
  end
end
