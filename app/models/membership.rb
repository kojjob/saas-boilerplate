# frozen_string_literal: true

class Membership < ApplicationRecord
  # Associations
  belongs_to :user, optional: true # Optional for pending invitations
  belongs_to :account
  belongs_to :invited_by, class_name: 'User', optional: true

  # Enums
  enum :role, { owner: 'owner', admin: 'admin', member: 'member', guest: 'guest' }, default: :member

  # Validations
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :account_id, message: 'is already a member of this account' }, allow_nil: true
  validate :owner_role_immutable, on: :update
  validate :single_owner_per_account, on: :create

  # Callbacks
  before_destroy :prevent_owner_destruction

  # Scopes
  scope :active, -> { where.not(accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil).where.not(invitation_token: nil) }
  scope :owners, -> { where(role: 'owner') }
  scope :admins, -> { where(role: %w[owner admin]) }

  # Class methods
  def self.invite!(account:, email:, role:, invited_by:)
    create!(
      account: account,
      invitation_email: email.downcase.strip,
      role: role,
      invited_by: invited_by,
      invitation_token: SecureRandom.urlsafe_base64(32),
      invited_at: Time.current
    )
  end

  # Instance methods
  def admin_or_owner?
    owner? || admin?
  end

  def can_manage_members?
    admin_or_owner?
  end

  def can_manage_billing?
    owner?
  end

  def pending_invitation?
    invitation_token.present? && accepted_at.nil?
  end

  def accept_invitation!(user)
    update!(
      user: user,
      accepted_at: Time.current,
      invitation_token: nil
    )
  end

  def invitation_expired?
    return false unless invited_at.present?

    invited_at < 7.days.ago
  end

  def resend_invitation!
    update!(
      invitation_token: SecureRandom.urlsafe_base64(32),
      invited_at: Time.current
    )
  end

  private

  def owner_role_immutable
    return unless role_changed? && role_was == 'owner'

    errors.add(:role, "cannot be changed for the account owner")
  end

  def single_owner_per_account
    return unless owner?
    return unless account&.memberships&.owners&.exists?

    errors.add(:role, "account already has an owner")
  end

  def prevent_owner_destruction
    return unless owner?

    errors.add(:base, "Cannot remove the account owner")
    throw :abort
  end
end
