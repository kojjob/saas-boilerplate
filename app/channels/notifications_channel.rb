# frozen_string_literal: true

class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def mark_as_read(data)
    notification = current_user.notifications.find_by(id: data["notification_id"])
    notification&.mark_as_read!
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    ActionCable.server.broadcast(
      "notifications_#{current_user.id}",
      { action: "all_read" }
    )
  end
end
