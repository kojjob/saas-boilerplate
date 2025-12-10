# frozen_string_literal: true

# OnboardingProgress tracks a user's progress through the initial onboarding checklist
# It monitors key milestones: create client, create project, create invoice, send invoice
class OnboardingProgress < ApplicationRecord
  STEPS = %i[client_created project_created invoice_created invoice_sent].freeze

  belongs_to :user

  validates :user_id, uniqueness: true

  # Find or create onboarding progress for a user
  def self.find_or_create_for(user)
    find_or_create_by(user: user)
  end

  # Mark a step as complete with a timestamp
  def complete_step!(step)
    step = step.to_sym
    raise ArgumentError, "Invalid step: #{step}" unless STEPS.include?(step)

    return if send(step) # Already complete

    update!(
      step => true,
      "#{step}_at" => Time.current
    )
  end

  # Count of completed steps
  def completed_steps_count
    STEPS.count { |step| send(step) }
  end

  # Total number of steps
  def total_steps
    STEPS.length
  end

  # Progress as a percentage (0-100)
  def progress_percentage
    (completed_steps_count.to_f / total_steps * 100).to_i
  end

  # Check if all steps are completed
  def completed?
    STEPS.all? { |step| send(step) }
  end

  # Check if the checklist should be shown
  def visible?
    !dismissed && !completed?
  end

  # Dismiss the checklist
  def dismiss!
    update!(dismissed: true, dismissed_at: Time.current)
  end

  # Get the next incomplete step
  def next_step
    STEPS.find { |step| !send(step) }
  end

  # Human-readable step information
  def step_info(step)
    case step.to_sym
    when :client_created
      {
        title: "Add your first client",
        description: "Create a client to start tracking work",
        path_helper: :new_client_path,
        icon: "users"
      }
    when :project_created
      {
        title: "Create a project",
        description: "Organize your work by project",
        path_helper: :new_project_path,
        icon: "folder"
      }
    when :invoice_created
      {
        title: "Create an invoice",
        description: "Bill your client for completed work",
        path_helper: :new_invoice_path,
        icon: "document-text"
      }
    when :invoice_sent
      {
        title: "Send your first invoice",
        description: "Get paid by sending an invoice to your client",
        path_helper: :invoices_path,
        icon: "paper-airplane"
      }
    end
  end
end
