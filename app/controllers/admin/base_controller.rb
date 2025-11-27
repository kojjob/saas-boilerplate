# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_site_admin!

    layout "admin"

    private

    def require_site_admin!
      unless current_user&.site_admin?
        redirect_to root_path, alert: "You are not authorized to access this area."
      end
    end

    # Impersonation helpers
    def impersonating?
      session[:admin_user_id].present?
    end

    def original_admin
      @original_admin ||= User.find_by(id: session[:admin_user_id])
    end

    helper_method :impersonating?, :original_admin
  end
end
