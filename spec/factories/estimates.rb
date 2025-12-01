# frozen_string_literal: true

FactoryBot.define do
  factory :estimate do
    association :account
    association :client
    estimate_number { "EST-#{Faker::Number.unique.number(digits: 5)}" }
    issue_date { Date.current }
    valid_until { Date.current + 30.days }
    status { :draft }
    subtotal { 1000.00 }
    tax_rate { 0 }
    tax_amount { 0 }
    discount_amount { 0 }
    total_amount { 1000.00 }
    notes { Faker::Lorem.paragraph }
    terms { "Valid for 30 days. Subject to change." }

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :viewed do
      status { :viewed }
      sent_at { Time.current - 1.hour }
      viewed_at { Time.current }
    end

    trait :accepted do
      status { :accepted }
      sent_at { Time.current - 2.hours }
      viewed_at { Time.current - 1.hour }
      accepted_at { Time.current }
    end

    trait :declined do
      status { :declined }
      sent_at { Time.current - 2.hours }
      viewed_at { Time.current - 1.hour }
      declined_at { Time.current }
    end

    trait :expired do
      status { :expired }
      valid_until { Date.current - 1.day }
    end

    trait :converted do
      status { :converted }
      accepted_at { Time.current - 1.hour }
      converted_at { Time.current }
    end

    trait :with_line_items do
      after(:create) do |estimate|
        create_list(:estimate_line_item, 3, estimate: estimate)
        estimate.reload
        estimate.save # Trigger total calculation
      end
    end

    trait :with_project do
      association :project
    end
  end
end
