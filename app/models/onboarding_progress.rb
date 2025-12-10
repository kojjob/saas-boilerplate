# frozen_string_literal: true

class OnboardingProgress < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  STEPS = [
    { key: :created_client, title: "Create your first client", description: "Add a client to start tracking work" },
    { key: :created_project, title: "Create a project", description: "Organize work into projects" },
    { key: :created_invoice, title: "Create an invoice", description: "Bill your client for work completed" },
    { key: :sent_invoice, title: "Send an invoice", description: "Email the invoice to your client" }
  ].freeze

  scope :active, -> { where(dismissed_at: nil, completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :dismissed, -> { where.not(dismissed_at: nil) }

  # Mark a step as completed
  def complete_step!(step_key)
    column = "#{step_key}_at"
    return unless respond_to?(column)
    return if send(column).present? # Don't overwrite existing timestamp

    update!(column => Time.current)
    check_completion!
  end

  # Check if a specific step is completed
  def step_completed?(step_key)
    send("#{step_key}_at").present?
  end

  # Calculate completion percentage (0-100)
  def completion_percentage
    return 0 if total_steps.zero?

    ((completed_steps_count.to_f / total_steps) * 100).to_i
  end

  # Count of completed steps
  def completed_steps_count
    STEPS.count { |step| step_completed?(step[:key]) }
  end

  # Total number of steps
  def total_steps
    STEPS.length
  end

  # Status checks
  def dismissed?
    dismissed_at.present?
  end

  def completed?
    completed_at.present?
  end

  def active?
    !dismissed? && !completed?
  end

  # Dismiss the onboarding checklist
  def dismiss!
    update!(dismissed_at: Time.current)
  end

  # Get the next incomplete step
  def next_step
    STEPS.find { |step| !step_completed?(step[:key]) }&.dig(:key)
  end

  # Get summary of all steps with completion status
  def steps_summary
    STEPS.map do |step|
      {
        key: step[:key],
        title: step[:title],
        description: step[:description],
        completed: step_completed?(step[:key]),
        completed_at: send("#{step[:key]}_at")
      }
    end
  end

  private

  # Auto-complete when all steps are done
  def check_completion!
    return if completed?
    return unless STEPS.all? { |step| step_completed?(step[:key]) }

    update!(completed_at: Time.current)
  end
end
