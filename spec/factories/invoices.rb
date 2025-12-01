# frozen_string_literal: true

FactoryBot.define do
  factory :invoice do
    account
    client { association :client, account: account }
    project { nil }
    invoice_number { nil } # Let the model generate it
    status { :draft }
    issue_date { Date.current }
    due_date { Date.current + 30.days }
    subtotal { 1000.00 }
    tax_rate { 0 }
    tax_amount { 0 }
    discount_amount { 0 }
    total_amount { 1000.00 }
    notes { Faker::Lorem.sentence }

    trait :with_project do
      association :project
    end

    trait :draft do
      status { :draft }
    end

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :viewed do
      status { :viewed }
      sent_at { 2.days.ago }
    end

    trait :paid do
      status { :paid }
      sent_at { 1.week.ago }
      paid_at { Time.current }
      payment_method { "check" }
      payment_reference { "CHK-#{Faker::Number.number(digits: 6)}" }
    end

    trait :overdue do
      status { :overdue }
      sent_at { 45.days.ago }
      issue_date { 45.days.ago }
      due_date { 15.days.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_tax do
      tax_rate { 8.5 }
      tax_amount { 85.00 }
      total_amount { 1085.00 }
    end

    trait :with_discount do
      discount_amount { 100.00 }
      total_amount { 900.00 }
    end

    trait :with_line_items do
      after(:create) do |invoice|
        create_list(:invoice_line_item, 3, invoice: invoice)
        invoice.reload
      end
    end
  end

  factory :invoice_line_item do
    association :invoice
    description { Faker::Commerce.product_name }
    quantity { Faker::Number.between(from: 1, to: 10) }
    unit_price { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    amount { quantity * unit_price }
    position { 0 }
  end
end
