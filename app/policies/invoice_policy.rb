# frozen_string_literal: true

class InvoicePolicy < ApplicationPolicy
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
    admin_or_owner? && !record.paid?
  end

  def edit?
    update?
  end

  def destroy?
    admin_or_owner? && record.draft?
  end

  def send_invoice?
    admin_or_owner? && record.draft?
  end

  def mark_paid?
    admin_or_owner? && record.payable?
  end

  def mark_cancelled?
    admin_or_owner? && !record.paid?
  end

  def preview?
    account_member?
  end

  def download?
    account_member?
  end

  class Scope < Scope
    def resolve
      scope.where(account: current_account)
    end
  end
end
