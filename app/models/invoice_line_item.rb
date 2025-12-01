# frozen_string_literal: true

class InvoiceLineItem < ApplicationRecord
  # Associations
  belongs_to :invoice

  # Validations
  validates :description, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  before_save :calculate_amount

  # Scopes
  default_scope { order(:position, :created_at) }

  private

  def calculate_amount
    self.amount = (quantity || 0) * (unit_price || 0)
  end
end
