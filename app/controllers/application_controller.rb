class ApplicationController < ActionController::Base
  include Authentication
  include TenantScoping
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

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
end
