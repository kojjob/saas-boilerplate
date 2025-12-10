# frozen_string_literal: true

class Expense < ApplicationRecord
  include Currencyable

  belongs_to :account
  belongs_to :project, optional: true
  belongs_to :client, optional: true

  has_one_attached :receipt

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :category, presence: true

  enum :category, {
    software: 0,
    hardware: 1,
    travel: 2,
    meals: 3,
    office: 4,
    professional_services: 5,
    marketing: 6,
    utilities: 7,
    subscriptions: 8,
    other: 9
  }

  scope :recent, -> { order(expense_date: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :this_month, -> { where(expense_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :this_year, -> { where(expense_date: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :billable, -> { where(billable: true) }
  scope :reimbursable, -> { where(reimbursable: true) }
  scope :search, ->(query) {
    where("description ILIKE :q OR vendor ILIKE :q", q: "%#{query}%")
  }

  before_validation :set_default_currency, on: :create

  # Instance methods
  def formatted_amount
    "#{currency_symbol}#{sprintf('%.2f', amount)}"
  end

  def receipt_attached?
    receipt.attached?
  end

  def category_display_name
    category.to_s.humanize
  end

  def effective_client
    client || project&.client
  end

  # Class methods
  def self.total_amount
    sum(:amount)
  end

  def self.by_category_summary
    group(:category).sum(:amount).transform_keys(&:to_sym)
  end

  private

  def set_default_currency
    return if currency.present?

    self.currency = account&.default_currency || "USD"
  end
end
