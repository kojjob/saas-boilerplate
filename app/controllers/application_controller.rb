class ApplicationController < ActionController::Base
  include Authentication
  include TenantScoping
  include Pundit::Authorization

  # Verify tenant access for authenticated users accessing tenant-scoped resources
  after_action :verify_tenant_access_for_user, if: -> { current_user && current_account }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_access_denied

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Disabled in test environment to avoid test failures
  unless Rails.env.test?
    allow_browser versions: :modern
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def user_not_authorized
    flash[:alert] = "You don't have permission to perform this action."
    redirect_back(fallback_location: dashboard_path)
  end

  def record_not_found
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Record not found" }, status: :not_found }
    end
  end

  def tenant_access_denied
    flash[:alert] = "You don't have access to this account."
    redirect_to dashboard_path
  end

  def verify_tenant_access_for_user
    return unless current_user && current_account
    return if current_user.accounts.include?(current_account)

    # Log the unauthorized access attempt
    Rails.logger.warn "User #{current_user.id} attempted to access account #{current_account.id} without membership"
  end
end
