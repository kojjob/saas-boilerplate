# frozen_string_literal: true

class Estimate < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :converted_invoice, class_name: "Invoice", optional: true
  has_many :line_items, class_name: "EstimateLineItem", dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  # Enums
  enum :status, {
    draft: 0,
    sent: 1,
    viewed: 2,
    accepted: 3,
    declined: 4,
    expired: 5,
    converted: 6
  }, default: :draft

  # Validations
  validates :estimate_number, presence: true, uniqueness: { scope: :account_id }
  validates :issue_date, presence: true
  validates :valid_until, presence: true
  validate :valid_until_after_issue_date
  validate :can_convert_validation, on: :convert

  # Callbacks
  before_validation :set_default_dates, on: :create
  before_validation :generate_estimate_number, on: :create, if: -> { estimate_number.blank? }
  before_save :calculate_totals

  # Scopes
  scope :pending, -> { where(status: [:draft, :sent]) }
  scope :active, -> { where.not(status: [:expired, :declined, :converted]) }
  scope :expiring_soon, -> { pending.where("valid_until <= ?", 7.days.from_now) }
  scope :recent, -> { order(issue_date: :desc) }
  scope :search, ->(query) {
    return all if query.blank?
    left_joins(:client).where(
      "estimates.estimate_number ILIKE :query OR clients.name ILIKE :query OR clients.company ILIKE :query",
      query: "%#{query}%"
    )
  }

  # Instance Methods
  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_viewed!
    update!(status: :viewed, viewed_at: Time.current) if sent?
  end

  def mark_as_accepted!
    update!(status: :accepted, accepted_at: Time.current)
  end

  def mark_as_declined!
    update!(status: :declined, declined_at: Time.current)
  end

  def mark_as_expired!
    update!(status: :expired) if expired? && !converted? && !accepted?
  end

  def expired?
    valid_until < Date.current
  end

  def days_until_expiry
    return 0 if expired?
    (valid_until - Date.current).to_i
  end

  def can_convert?
    accepted? && !converted?
  end

  def convert_to_invoice!
    raise ActiveRecord::RecordInvalid.new(self) unless can_convert?

    transaction do
      invoice = Invoice.create!(
        account: account,
        client: client,
        project: project,
        issue_date: Date.current,
        due_date: Date.current + 30.days,
        tax_rate: tax_rate,
        discount_amount: discount_amount,
        notes: notes,
        terms: terms
      )

      line_items.each do |item|
        invoice.line_items.create!(
          description: item.description,
          quantity: item.quantity,
          unit_price: item.unit_price,
          position: item.position
        )
      end

      update!(
        status: :converted,
        converted_invoice: invoice,
        converted_at: Time.current
      )

      invoice
    end
  end

  def status_color
    case status.to_sym
    when :draft then "gray"
    when :sent then "blue"
    when :viewed then "indigo"
    when :accepted then "green"
    when :declined then "red"
    when :expired then "amber"
    when :converted then "purple"
    else "gray"
    end
  end

  private

  def set_default_dates
    self.issue_date ||= Date.current
    self.valid_until ||= issue_date + 30.days
  end

  def valid_until_after_issue_date
    return unless issue_date && valid_until
    if valid_until < issue_date
      errors.add(:valid_until, "must be after issue date")
    end
  end

  def can_convert_validation
    unless can_convert?
      errors.add(:base, "Estimate must be accepted and not already converted")
    end
  end

  def generate_estimate_number
    last_number = account.estimates.where.not(estimate_number: nil)
                         .order(Arel.sql("CAST(SUBSTRING(estimate_number FROM '[0-9]+') AS INTEGER) DESC NULLS LAST"))
                         .limit(1)
                         .pick(:estimate_number)

    next_number = if last_number
      last_number.gsub(/[^0-9]/, "").to_i + 1
    else
      10001
    end

    self.estimate_number = "EST-#{next_number}"
  end

  def calculate_totals
    # Only calculate from line items if there are any
    if line_items.any? { |li| !li.marked_for_destruction? }
      self.subtotal = line_items.reject(&:marked_for_destruction?).sum { |li| li.amount || 0 }
      self.tax_amount = (subtotal * (tax_rate || 0) / 100).round(2)
      self.total_amount = subtotal + tax_amount - (discount_amount || 0)
    else
      # If no line items, use manually set values or defaults
      self.subtotal ||= 0
      self.tax_amount ||= 0
      self.total_amount ||= subtotal + tax_amount - (discount_amount || 0)
    end
  end
end
