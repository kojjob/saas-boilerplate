# frozen_string_literal: true

class ExportPolicy < ApplicationPolicy
  # Exports are not model instances, so we use a headless policy
  # The record is just a symbol (:export) used for authorization

  def new?
    # Members and above can view the export form
    member_or_above?
  end

  def create?
    # Members and above can generate exports
    member_or_above?
  end

  private

  # Members, admins, and owners can export data
  # Guests cannot export sensitive financial information
  def member_or_above?
    account_member? && !guest?
  end
end
