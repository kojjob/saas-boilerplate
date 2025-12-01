# frozen_string_literal: true

class MaterialEntry < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :project
  belongs_to :user

  # Validations
  validates :name, presence: true
  validates :date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_save :calculate_total_amount

  # Scopes
  scope :billable, -> { where(billable: true) }
  scope :non_billable, -> { where(billable: false) }
  scope :invoiced, -> { where(invoiced: true) }
  scope :not_invoiced, -> { where(invoiced: false) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }

  # Instance Methods
  def subtotal
    (quantity || 0) * (unit_cost || 0)
  end

  def markup_amount
    subtotal * ((markup_percentage || 0) / 100.0)
  end

  def mark_as_invoiced!
    update!(invoiced: true)
  end

  private

  def calculate_total_amount
    self.total_amount = subtotal + markup_amount if billable?
  end
end
