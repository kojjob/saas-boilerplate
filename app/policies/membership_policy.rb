# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  # Anyone with a membership in the account can view the team list
  def index?
    account_member?
  end

  # Show details of a membership
  def show?
    account_member?
  end

  # Only owners and admins can invite new members
  def invite?
    admin_or_owner?
  end

  def new?
    invite?
  end

  def create?
    invite?
  end

  # Update a membership (change role)
  # - Owner can update anyone except themselves
  # - Admin can update members and guests (not other admins or owner)
  # - No one can update their own membership
  def update?
    return false unless admin_or_owner?
    return false if own_membership?

    if owner?
      true
    elsif admin?
      # Admins can only update members and guests, not other admins or owner
      record.member? || record.guest?
    else
      false
    end
  end

  def edit?
    update?
  end

  # Destroy a membership (remove from account)
  # - Owner can remove anyone except themselves
  # - Admin can remove members and guests (not other admins or owner)
  # - Members/Guests can only remove themselves (leave account)
  def destroy?
    return false if record.owner? && own_membership? # Owner can never be removed

    if owner?
      !own_membership? # Owner can remove anyone except themselves
    elsif admin?
      if own_membership?
        false # Admins cannot remove themselves
      else
        # Admins can only remove members and guests
        record.member? || record.guest?
      end
    else
      # Members and guests can only leave (remove their own membership)
      own_membership?
    end
  end

  # Resend invitation email
  def resend_invitation?
    admin_or_owner? && record.pending_invitation?
  end

  # Cancel a pending invitation
  def cancel_invitation?
    admin_or_owner? && record.pending_invitation?
  end

  private

  def own_membership?
    record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless ActsAsTenant.current_tenant

      scope.where(account: ActsAsTenant.current_tenant)
    end
  end
end
