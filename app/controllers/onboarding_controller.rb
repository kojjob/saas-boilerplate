# frozen_string_literal: true

class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def dismiss
    onboarding = OnboardingProgress.find_by(user: current_user)
    onboarding&.dismiss!

    redirect_back(fallback_location: dashboard_path)
  end
end
