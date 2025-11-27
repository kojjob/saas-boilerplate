# frozen_string_literal: true

# TenantScoped provides automatic tenant scoping for models
# Include this concern in any model that should be isolated by account
#
# Example:
#   class Invoice < ApplicationRecord
#     include TenantScoped
#   end
#
module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant(:account)

    validates :account_id, presence: true
  end
end
