# frozen_string_literal: true

module Owner
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_site_admin!

    layout "owner"

    private

    def require_site_admin!
      return if current_user&.site_admin?

      flash[:alert] = "You don't have permission to access the Owner Portal."
      redirect_to dashboard_path
    end
  end
end
