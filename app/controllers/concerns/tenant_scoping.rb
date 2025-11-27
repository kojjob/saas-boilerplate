# frozen_string_literal: true

# TenantScoping provides multi-tenant isolation using acts_as_tenant
# Tenants are resolved via subdomain or account switch for users with multiple memberships
module TenantScoping
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    before_action :set_current_tenant_from_subdomain, if: :subdomain_request?
    before_action :set_current_tenant_from_session, unless: :subdomain_request?
    helper_method :current_account
  end

  private

  def current_account
    ActsAsTenant.current_tenant
  end

  def subdomain_request?
    request.subdomain.present? && request.subdomain != "www"
  end

  def set_current_tenant_from_subdomain
    account = Account.find_by(subdomain: request.subdomain)
    set_current_tenant(account) if account
  end

  def set_current_tenant_from_session
    return unless session[:current_account_id]

    account = Account.find_by(id: session[:current_account_id])
    set_current_tenant(account) if account
  end

  # Allow setting tenant for authenticated users who belong to multiple accounts
  def set_tenant_for_user(user, account = nil)
    return unless user

    target_account = account || user.accounts.first
    return unless target_account && user.accounts.include?(target_account)

    set_current_tenant(target_account)
    session[:current_account_id] = target_account.id
  end

  # Verify user has access to current tenant
  def verify_tenant_access!
    return unless current_user && current_account
    return if current_user.accounts.include?(current_account)

    raise ActsAsTenant::Errors::NoTenantSet, "User does not have access to this account"
  end
end
