# frozen_string_literal: true

class Message < ApplicationRecord
  # Associations
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :account, optional: true

  # Validations
  validates :body, presence: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create_commit :broadcast_message

  # Instance methods
  def mark_as_read!
    update!(read_at: Time.current)
  end

  def unread?
    read_at.nil?
  end

  # Class methods
  def self.unread_count_for(user)
    where(recipient: user, read_at: nil).count
  end

  private

  def broadcast_message
    ActionCable.server.broadcast(
      "conversation_#{conversation_id}",
      {
        message: {
          id: id,
          body: body,
          sender_id: sender_id,
          recipient_id: recipient_id,
          read_at: read_at,
          created_at: created_at
        }
      }
    )
  end
end
