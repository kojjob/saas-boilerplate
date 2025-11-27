# frozen_string_literal: true

# ActsAsTenant Configuration
# Provides row-level multi-tenancy by scoping all queries to the current tenant
ActsAsTenant.configure do |config|
  # Require a tenant to be set for all requests
  # Set to false initially during development, can be enabled per-controller
  config.require_tenant = false

  # Specify the model used as the tenant
  config.pkey = :id
end
