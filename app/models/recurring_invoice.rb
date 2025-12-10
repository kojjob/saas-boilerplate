# frozen_string_literal: true

class RecurringInvoice < ApplicationRecord
  include Currencyable

  # Associations
  belongs_to :account
  belongs_to :client
  belongs_to :project, optional: true
  has_many :invoices, dependent: :nullify
  has_many :line_items, class_name: "RecurringInvoiceLineItem", dependent: :destroy
  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  # Enums
  enum :frequency, {
    weekly: 0,
    biweekly: 1,
    monthly: 2,
    quarterly: 3,
    annually: 4
  }

  enum :status, {
    active: 0,
    paused: 1,
    cancelled: 2,
    completed: 3
  }

  # Validations
  validates :name, presence: true
  validates :frequency, presence: true
  validates :start_date, presence: true
  validates :payment_terms, numericality: { greater_than_or_equal_to: 0 }
  validates :occurrences_limit, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :due_for_generation, -> {
    active.where("next_occurrence_date <= ?", Date.current)
  }

  # Callbacks
  before_create :set_next_occurrence_date

  # Instance Methods

  # Advances the next occurrence date based on frequency
  # and increments the occurrence count
  def advance_next_occurrence!
    self.next_occurrence_date = calculate_next_date
    self.occurrences_count += 1
    self.last_generated_at = Date.current

    # Check if we should complete this recurring invoice
    if should_complete?
      self.status = :completed
    end

    save!
  end

  # Determines if an invoice can be generated
  def can_generate?
    return false unless active?
    return false if next_occurrence_date.nil? || next_occurrence_date > Date.current
    return false if end_date.present? && end_date < Date.current
    return false if occurrences_limit.present? && occurrences_count >= occurrences_limit

    true
  end

  # Status management methods
  def pause!
    update!(status: :paused)
  end

  def resume!
    update!(status: :active)
  end

  def cancel!
    update!(status: :cancelled)
  end

  # Display helpers
  def frequency_display_name
    frequency.humanize
  end

  def remaining_occurrences
    return nil if occurrences_limit.nil?
    occurrences_limit - occurrences_count
  end

  private

  def set_next_occurrence_date
    self.next_occurrence_date ||= start_date
  end

  def calculate_next_date
    case frequency
    when "weekly"
      next_occurrence_date + 1.week
    when "biweekly"
      next_occurrence_date + 2.weeks
    when "monthly"
      next_occurrence_date + 1.month
    when "quarterly"
      next_occurrence_date + 3.months
    when "annually"
      next_occurrence_date + 1.year
    else
      next_occurrence_date + 1.month
    end
  end

  def should_complete?
    # Check occurrence limit
    if occurrences_limit.present? && occurrences_count >= occurrences_limit
      return true
    end

    # Check end date - if next occurrence would be past end date
    if end_date.present? && next_occurrence_date > end_date
      return true
    end

    false
  end
end
