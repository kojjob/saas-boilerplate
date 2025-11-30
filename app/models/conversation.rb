# frozen_string_literal: true

class Conversation < ApplicationRecord
  # Associations
  belongs_to :participant_1, class_name: "User"
  belongs_to :participant_2, class_name: "User"
  belongs_to :account, optional: true
  has_many :messages, dependent: :destroy

  # Validations
  validate :participants_are_different
  validate :unique_conversation_between_participants, on: :create

  # Scopes
  scope :for_user, ->(user) {
    where("participant_1_id = ? OR participant_2_id = ?", user.id, user.id)
  }
  scope :recent, -> { order(updated_at: :desc) }

  # Class methods
  def self.find_or_create_between(user1, user2, account: nil)
    conversation = find_between(user1, user2)
    return conversation if conversation

    create!(
      participant_1: user1,
      participant_2: user2,
      account: account
    )
  end

  def self.find_between(user1, user2)
    where(participant_1: user1, participant_2: user2)
      .or(where(participant_1: user2, participant_2: user1))
      .first
  end

  # Instance methods
  def other_participant(user)
    participant_1 == user ? participant_2 : participant_1
  end

  def unread_count_for(user)
    messages.where(recipient: user, read_at: nil).count
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def participant?(user)
    participant_1 == user || participant_2 == user
  end

  private

  def participants_are_different
    if participant_1_id == participant_2_id
      errors.add(:participant_2_id, "can't be the same as participant 1")
    end
  end

  def unique_conversation_between_participants
    if Conversation.find_between(participant_1, participant_2).present?
      errors.add(:participant_1_id, "conversation already exists between these users")
    end
  end
end
