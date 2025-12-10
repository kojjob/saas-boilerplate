# frozen_string_literal: true

class Client < ApplicationRecord
  include Rails.application.routes.url_helpers

  # Associations
  belongs_to :account
  has_many :projects, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :estimates, dependent: :destroy

  # Enums
  enum :status, { active: 0, archived: 1 }, default: :active

  # Validations
  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :account_id, case_sensitive: false }

  # Normalizations
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip }

  # Scopes
  scope :search, ->(query) {
    return all if query.blank?
    where("name ILIKE :query OR email ILIKE :query OR company ILIKE :query", query: "%#{query}%")
  }
  scope :with_portal_access, -> { where(portal_enabled: true).where.not(portal_token: nil) }

  # Class Methods
  def self.find_by_portal_token(token)
    return nil if token.blank?

    with_portal_access.find_by(portal_token: token)
  end

  # Instance Methods
  def display_name
    company.presence || name
  end

  def full_address
    street_parts = [ address_line1, address_line2 ].compact_blank
    city_state_zip = [ city, "#{state} #{postal_code}".strip.presence ].compact_blank.join(", ")
    all_parts = [ street_parts.join(", ").presence, city_state_zip.presence, country ].compact_blank
    all_parts.any? ? all_parts.join(", ") : nil
  end

  def archive!
    update!(status: :archived)
  end

  def activate!
    update!(status: :active)
  end

  def total_revenue
    invoices.paid.sum(:total_amount)
  end

  def outstanding_balance
    invoices.unpaid.sum(:total_amount)
  end

  def initials
    return "??" if name.blank?

    parts = name.split
    if parts.length >= 2
      "#{parts.first[0]}#{parts.last[0]}".upcase
    else
      name.first(2).upcase
    end
  end

  # Portal Access Methods
  def generate_portal_token!
    update!(
      portal_token: SecureRandom.hex(16),
      portal_token_generated_at: Time.current
    )
  end

  def regenerate_portal_token!
    generate_portal_token!
  end

  def revoke_portal_token!
    update!(
      portal_token: nil,
      portal_token_generated_at: nil
    )
  end

  def portal_url
    return nil if portal_token.blank?

    portal_dashboard_path(token: portal_token)
  end

  def portal_access_enabled?
    portal_enabled? && portal_token.present?
  end
end
