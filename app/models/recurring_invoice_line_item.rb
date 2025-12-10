# frozen_string_literal: true

class RecurringInvoiceLineItem < ApplicationRecord
  # Associations
  belongs_to :recurring_invoice

  # Validations
  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :calculate_amount

  # Scopes
  default_scope { order(position: :asc) }

  private

  def calculate_amount
    self.amount = (quantity.to_d * unit_price.to_d).round(2) if quantity.present? && unit_price.present?
  end
end
