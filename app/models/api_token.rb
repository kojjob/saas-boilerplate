# frozen_string_literal: true

class ApiToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  class << self
    def authenticate(token_string)
      return nil if token_string.blank?

      api_token = find_by(token: token_string)
      return nil unless api_token&.active?

      api_token.touch_last_used!
      api_token
    end

    def generate_for(user, expires_in: 30.days, name: nil)
      create!(
        user: user,
        expires_at: expires_in.from_now,
        name: name
      )
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end
end
