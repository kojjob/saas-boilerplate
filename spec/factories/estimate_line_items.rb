# frozen_string_literal: true

FactoryBot.define do
  factory :estimate_line_item do
    association :estimate
    description { Faker::Commerce.product_name }
    quantity { Faker::Number.between(from: 1, to: 10) }
    unit_price { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position { 0 }

    trait :high_value do
      quantity { 10 }
      unit_price { 500.00 }
    end

    trait :low_value do
      quantity { 1 }
      unit_price { 25.00 }
    end
  end
end
