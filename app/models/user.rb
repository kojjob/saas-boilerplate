# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  has_secure_password

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :sessions, dependent: :destroy

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

  private

  def generate_confirmation_token
    self.confirmation_token ||= SecureRandom.urlsafe_base64(32)
  end
end
