# frozen_string_literal: true

# Provides onboarding progress tracking for controllers
#
# Include this concern in controllers that need to track or display
# onboarding progress. It provides helper methods for:
# - Accessing the current user's onboarding progress
# - Tracking step completion
# - Determining if the checklist should be shown
#
# @example Include in a controller
#   class DashboardController < ApplicationController
#     include OnboardingTrackable
#   end
#
# @example Track a step completion
#   after_action -> { track_onboarding_step(:created_client) }, only: :create
#
module OnboardingTrackable
  extend ActiveSupport::Concern

  included do
    helper_method :current_onboarding, :show_onboarding_checklist?
  end

  private

  # Returns the current user's onboarding progress, creating one if needed
  #
  # @return [OnboardingProgress] the user's onboarding progress record
  def current_onboarding
    return @current_onboarding if defined?(@current_onboarding)

    @current_onboarding = OnboardingProgress.find_or_create_by(user: current_user)
  end

  # Determines if the onboarding checklist should be displayed
  #
  # @return [Boolean] true if the checklist should be shown
  def show_onboarding_checklist?
    return false unless current_user

    current_onboarding.active?
  end

  # Track completion of an onboarding step
  #
  # @param step_key [Symbol] the step to mark as completed
  #   (:created_client, :created_project, :created_invoice, :sent_invoice)
  def track_onboarding_step(step_key)
    return unless current_user

    current_onboarding.complete_step!(step_key)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[OnboardingTrackable] Failed to track step #{step_key}: #{e.message}")
  end
end
