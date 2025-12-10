# frozen_string_literal: true

FactoryBot.define do
  factory :recurring_invoice_line_item do
    association :recurring_invoice
    description { "Monthly consulting services" }
    quantity { 1 }
    unit_price { 500.00 }
    position { nil }
  end
end
