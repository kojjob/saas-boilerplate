# frozen_string_literal: true

class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def dismiss
    if current_onboarding
      current_onboarding.dismiss!
      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_back fallback_location: dashboard_path, notice: "Checklist dismissed." }
      end
    else
      respond_to do |format|
        format.json { head :not_found }
        format.html { redirect_back fallback_location: dashboard_path }
      end
    end
  end
end
