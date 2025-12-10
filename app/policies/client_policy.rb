# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  def index?
    account_member?
  end

  def show?
    account_member?
  end

  def create?
    admin_or_owner?
  end

  def new?
    create?
  end

  def update?
    admin_or_owner?
  end

  def edit?
    update?
  end

  def destroy?
    admin_or_owner?
  end

  def projects?
    account_member?
  end

  def invoices?
    account_member?
  end

  class Scope < Scope
    def resolve
      scope.where(account: current_account)
    end
  end
end
