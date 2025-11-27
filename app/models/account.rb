# frozen_string_literal: true

class Account < ApplicationRecord
  include Discard::Model
  include Cacheable

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 50 }
  validates :subdomain, uniqueness: { case_sensitive: false }, allow_nil: true,
                        format: { with: /\A[a-z0-9]+\z/i, message: "can only contain letters and numbers" }
  validate :subdomain_not_reserved

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_create :set_trial_period

  # Subscription statuses
  SUBSCRIPTION_STATUSES = %w[trialing active past_due canceled paused].freeze
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }

  # Reserved subdomains
  RESERVED_SUBDOMAINS = %w[www admin api app mail ftp smtp pop imap blog support help docs status].freeze

  # Scopes
  scope :active, -> { where(subscription_status: %w[trialing active]) }
  scope :trialing, -> { where(subscription_status: "trialing") }
  scope :paying, -> { where(subscription_status: "active") }

  # Instance methods
  def trial_expired?
    subscription_status == "trialing" && trial_ends_at.present? && trial_ends_at < Time.current
  end

  def active?
    return true if subscription_status == "active"
    return true if subscription_status == "trialing" && !trial_expired?

    false
  end

  def days_remaining_in_trial
    return 0 unless subscription_status == "trialing" && trial_ends_at.present?

    [ (trial_ends_at.to_date - Date.current).to_i, 0 ].max
  end

  def owner
    memberships.find_by(role: "owner")&.user
  end

  def admins
    users.joins(:memberships).where(memberships: { role: %w[owner admin] })
  end

  private

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug

    counter = 1
    while Account.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def set_trial_period
    self.trial_ends_at ||= 14.days.from_now
    self.subscription_status ||= "trialing"
  end

  def subdomain_not_reserved
    return unless subdomain.present? && RESERVED_SUBDOMAINS.include?(subdomain.downcase)

    errors.add(:subdomain, "is reserved")
  end
end
