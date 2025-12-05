# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # Returns the user's membership for the current account
  def current_membership
    return nil unless user && current_account

    @current_membership ||= user.memberships.find_by(account: current_account)
  end

  # Returns the current tenant/account
  def current_account
    ActsAsTenant.current_tenant
  end

  # Role check helpers
  def owner?
    current_membership&.owner?
  end

  def admin?
    current_membership&.admin?
  end

  def admin_or_owner?
    current_membership&.admin_or_owner?
  end

  def member?
    current_membership&.member?
  end

  def guest?
    current_membership&.guest?
  end

  # Check if user has a membership in the current account
  def account_member?
    current_membership.present?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    attr_reader :user, :scope

    # Returns the current tenant/account
    def current_account
      ActsAsTenant.current_tenant
    end
  end
end
