# frozen_string_literal: true

class Project < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :client
  has_many :invoices, dependent: :nullify
  has_many :documents, dependent: :destroy
  has_many :time_entries, dependent: :destroy
  has_many :material_entries, dependent: :destroy

  # Enums
  enum :status, {
    draft: 0,
    active: 1,
    on_hold: 2,
    completed: 3,
    cancelled: 4
  }, default: :draft

  # Validations
  validates :name, presence: true
  validates :project_number, uniqueness: { scope: :account_id, allow_nil: true }
  validate :client_belongs_to_same_account

  # Callbacks
  before_create :generate_project_number, if: -> { project_number.blank? }

  # Scopes
  scope :in_progress, -> { where(status: [ :draft, :active, :on_hold ]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) {
    return all if query.blank?
    where("name ILIKE :query OR project_number ILIKE :query OR description ILIKE :query", query: "%#{query}%")
  }

  # Instance Methods
  def full_address
    parts = [ address_line1, address_line2, city, state, postal_code ].compact_blank
    parts.any? ? parts.join(", ") : nil
  end

  def total_time_cost
    time_entries.billable.sum(:total_amount) || 0
  end

  def total_materials_cost
    material_entries.billable.sum(:total_amount) || 0
  end

  def total_project_cost
    total_time_cost + total_materials_cost
  end

  def total_hours
    time_entries.sum(:hours) || 0
  end

  def billable_hours
    time_entries.billable.sum(:hours) || 0
  end

  def invoiced_amount
    invoices.paid.sum(:total_amount) || 0
  end

  def pending_amount
    invoices.unpaid.sum(:total_amount) || 0
  end

  def budget_remaining
    return nil unless budget
    budget - total_project_cost
  end

  def budget_percentage_used
    return 0 unless budget && budget > 0
    ((total_project_cost.to_f / budget) * 100).round(1)
  end

  def overdue?
    due_date.present? && due_date < Date.current && !completed? && !cancelled?
  end

  def days_until_due
    return nil unless due_date
    (due_date - Date.current).to_i
  end

  private

  def generate_project_number
    last_number = account.projects.where.not(project_number: nil)
                         .order(Arel.sql("CAST(SUBSTRING(project_number FROM '[0-9]+') AS INTEGER) DESC NULLS LAST"))
                         .limit(1)
                         .pick(:project_number)

    next_number = if last_number
      last_number.gsub(/[^0-9]/, "").to_i + 1
    else
      1001
    end

    self.project_number = "PRJ-#{next_number.to_s.rjust(5, '0')}"
  end

  def client_belongs_to_same_account
    return unless client_id.present? && account_id.present?
    return if client&.account_id == account_id

    errors.add(:client, "must belong to the same account")
  end
end
