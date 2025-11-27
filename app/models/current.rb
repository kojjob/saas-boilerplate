# frozen_string_literal: true

# Thread-local storage for current request context
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :account
  attribute :session

  resets { Time.zone = nil }

  def user=(user)
    super
    Time.zone = user&.time_zone if user.respond_to?(:time_zone)
  end
end
