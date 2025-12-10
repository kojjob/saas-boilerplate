# frozen_string_literal: true

# OnboardingTrackable provides helper methods for tracking onboarding progress
# Include this concern in ApplicationController to make onboarding tracking available
module OnboardingTrackable
  extend ActiveSupport::Concern

  included do
    helper_method :current_onboarding if respond_to?(:helper_method)
  end

  private

  # Returns the current user's onboarding progress
  def current_onboarding
    return nil unless current_user

    @current_onboarding ||= OnboardingProgress.find_or_create_for(current_user)
  end

  # Track client creation step
  def track_client_created
    current_onboarding&.complete_step!(:client_created)
  end

  # Track project creation step
  def track_project_created
    current_onboarding&.complete_step!(:project_created)
  end

  # Track invoice creation step
  def track_invoice_created
    current_onboarding&.complete_step!(:invoice_created)
  end

  # Track invoice sent step
  def track_invoice_sent
    current_onboarding&.complete_step!(:invoice_sent)
  end
end
