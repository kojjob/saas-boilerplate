# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain

  def index
    redirect_to dashboard_path if signed_in?
  end
end
