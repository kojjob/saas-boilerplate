# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  include Cacheable

  has_secure_password

  # Audit logging - exclude sensitive fields
  audited except: %i[password_digest password reset_password_token confirmation_token]

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :sessions, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Conversations (user can be either participant)
  has_many :conversations_as_participant_1, class_name: "Conversation", foreign_key: :participant_1_id, dependent: :destroy
  has_many :conversations_as_participant_2, class_name: "Conversation", foreign_key: :participant_2_id, dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: :recipient_id, dependent: :destroy

  # Business domain associations
  has_many :time_entries, dependent: :destroy
  has_many :material_entries, dependent: :destroy
  has_many :uploaded_documents, class_name: "Document", foreign_key: :uploaded_by_id, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Callbacks
  normalizes :email, with: ->(email) { email.strip.downcase }
  before_create :generate_confirmation_token

  # Scopes
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def regenerate_confirmation_token!
    update!(confirmation_token: SecureRandom.urlsafe_base64(32))
  end

  def generate_password_reset_token!
    update!(
      reset_password_token: SecureRandom.urlsafe_base64(32),
      reset_password_sent_at: Time.current
    )
  end

  def password_reset_expired?
    reset_password_sent_at.present? && reset_password_sent_at < 2.hours.ago
  end

  def clear_password_reset_token!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  def membership_for(account)
    memberships.find_by(account: account)
  end

  def role_for(account)
    membership_for(account)&.role
  end

  def owner_of?(account)
    membership_for(account)&.owner?
  end

  def admin_of?(account)
    membership = membership_for(account)
    membership&.admin? || membership&.owner?
  end

  def member_of?(account)
    membership_for(account).present?
  end

  def conversations
    Conversation.for_user(self)
  end

  def unread_messages_count
    received_messages.unread.count
  end

  # Site-wide admin check (separate from account membership roles)
  def site_admin?
    site_admin == true
  end

  private

  def generate_confirmation_token
    self.confirmation_token ||= SecureRandom.urlsafe_base64(32)
  end
end
