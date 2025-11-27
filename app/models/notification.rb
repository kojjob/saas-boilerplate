# frozen_string_literal: true

class Notification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true
  belongs_to :account, optional: true

  # Validations
  validates :title, presence: true
  validates :notification_type, presence: true

  # Enums
  enum :notification_type, { info: 0, success: 1, warning: 2, error: 3 }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create_commit :broadcast_notification

  # Instance methods
  def mark_as_read!
    update!(read_at: Time.current)
  end

  def unread?
    read_at.nil?
  end

  # Class methods
  def self.create_for_user(user:, title:, body: nil, notification_type: :info, notifiable: nil, account: nil)
    create!(
      user: user,
      title: title,
      body: body,
      notification_type: notification_type,
      notifiable: notifiable,
      account: account
    )
  end

  private

  def broadcast_notification
    ActionCable.server.broadcast(
      "notifications_#{user_id}",
      {
        notification: {
          id: id,
          title: title,
          body: body,
          notification_type: notification_type,
          read_at: read_at,
          created_at: created_at
        }
      }
    )
  end
end
