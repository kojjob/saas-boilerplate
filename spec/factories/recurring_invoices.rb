# frozen_string_literal: true

FactoryBot.define do
  factory :recurring_invoice do
    association :account
    association :client
    name { "Monthly Retainer" }
    frequency { :monthly }
    status { :active }
    start_date { Date.current }
    next_occurrence_date { nil }  # Let callback set this from start_date
    payment_terms { 30 }
    currency { "USD" }
    tax_rate { 0 }
    notes { nil }
    occurrences_count { 0 }

    trait :active do
      status { :active }
    end

    trait :paused do
      status { :paused }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :completed do
      status { :completed }
    end

    trait :weekly do
      frequency { :weekly }
      name { "Weekly Service" }
    end

    trait :biweekly do
      frequency { :biweekly }
      name { "Bi-Weekly Service" }
    end

    trait :monthly do
      frequency { :monthly }
      name { "Monthly Retainer" }
    end

    trait :quarterly do
      frequency { :quarterly }
      name { "Quarterly Service" }
    end

    trait :annually do
      frequency { :annually }
      name { "Annual Subscription" }
    end

    trait :with_project do
      association :project
    end

    trait :with_line_items do
      after(:create) do |recurring_invoice|
        create_list(:recurring_invoice_line_item, 2, recurring_invoice: recurring_invoice)
      end
    end

    trait :with_end_date do
      end_date { Date.current + 1.year }
    end

    trait :with_limit do
      occurrences_limit { 12 }
    end
  end
end
