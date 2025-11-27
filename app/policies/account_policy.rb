# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  # Any member can view the account
  def show?
    account_member?
  end

  # Only owners and admins can update account settings
  def update?
    admin_or_owner?
  end

  def edit?
    update?
  end

  # Only owners can manage billing
  def manage_billing?
    owner?
  end

  # Only owners can delete the account
  def destroy?
    owner?
  end

  # Only owners can transfer ownership
  def transfer_ownership?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end
end
