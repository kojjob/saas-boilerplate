# frozen_string_literal: true

class Invoice < ApplicationRecord
  # Secure token for payment links
  has_secure_token :payment_token

  # Associations
  belongs_to :account
  belongs_to :client
  belongs_to :project, optional: true
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  # Enums
  enum :status, {
    draft: 0,
    sent: 1,
    viewed: 2,
    paid: 3,
    overdue: 4,
    cancelled: 5
  }, default: :draft

  # Validations
  validates :invoice_number, presence: true, uniqueness: { scope: :account_id }
  validates :issue_date, presence: true
  validates :due_date, presence: true
  validate :due_date_after_issue_date

  # Callbacks
  before_validation :set_default_dates, on: :create
  before_validation :generate_invoice_number, on: :create, if: -> { invoice_number.blank? }
  before_validation :generate_payment_token, on: :create
  before_save :calculate_totals

  # Scopes
  scope :with_status_paid, -> { where(status: :paid) }
  scope :unpaid, -> { where(status: [ :sent, :viewed, :overdue ]) }
  scope :outstanding, -> { unpaid }
  scope :recent, -> { order(issue_date: :desc) }
  scope :due_soon, -> { unpaid.where("due_date <= ?", 7.days.from_now) }
  scope :past_due, -> { unpaid.where("due_date < ?", Date.current) }
  scope :search, ->(query) {
    return all if query.blank?
    left_joins(:client).where(
      "invoices.invoice_number ILIKE :query OR clients.name ILIKE :query OR clients.company ILIKE :query",
      query: "%#{query}%"
    )
  }

  # Class Methods
  def self.find_by_payment_token!(token)
    find_by!(payment_token: token)
  end

  # Instance Methods
  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_paid!(payment_date: Time.current, payment_method: nil, payment_reference: nil)
    update!(
      status: :paid,
      paid_at: payment_date,
      payment_method: payment_method,
      payment_reference: payment_reference
    )
  end

  def mark_as_overdue!
    update!(status: :overdue) if unpaid? && past_due?
  end

  def unpaid?
    sent? || viewed? || overdue?
  end

  def past_due?
    due_date < Date.current
  end

  def days_overdue
    return 0 unless past_due?
    (Date.current - due_date).to_i
  end

  def days_until_due
    return 0 if past_due?
    (due_date - Date.current).to_i
  end

  def payment_status_color
    case status.to_sym
    when :draft then "gray"
    when :sent then "blue"
    when :viewed then "indigo"
    when :paid then "green"
    when :overdue then "red"
    when :cancelled then "gray"
    else "gray"
    end
  end

  def payment_url
    Rails.application.routes.url_helpers.pay_invoice_url(payment_token: payment_token, host: default_url_host)
  end

  def payable?
    sent? || viewed? || overdue?
  end

  private

  def default_url_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end

  def generate_payment_token
    self.payment_token ||= SecureRandom.hex(16)
  end

  def set_default_dates
    self.issue_date ||= Date.current
    self.due_date ||= issue_date + 30.days
  end

  def due_date_after_issue_date
    return unless issue_date && due_date
    if due_date < issue_date
      errors.add(:due_date, "must be after issue date")
    end
  end

  def generate_invoice_number
    last_number = account.invoices.where.not(invoice_number: nil)
                         .order(Arel.sql("CAST(SUBSTRING(invoice_number FROM '[0-9]+') AS INTEGER) DESC NULLS LAST"))
                         .limit(1)
                         .pick(:invoice_number)

    next_number = if last_number
      last_number.gsub(/[^0-9]/, "").to_i + 1
    else
      10001
    end

    self.invoice_number = "INV-#{next_number}"
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
