# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain

  def index
    return redirect_to dashboard_path if signed_in?

    # Load pricing plans for the landing page
    @monthly_plans = Plan.active.monthly.sorted
    @yearly_plans = Plan.active.yearly.sorted
  end
end
