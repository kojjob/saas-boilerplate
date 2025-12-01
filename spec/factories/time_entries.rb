# frozen_string_literal: true

FactoryBot.define do
  factory :time_entry do
    association :account
    association :project
    association :user
    date { Date.current }
    hours { Faker::Number.decimal(l_digits: 1, r_digits: 1) }
    hourly_rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    description { Faker::Lorem.sentence }
    billable { true }
    invoiced { false }

    trait :billable do
      billable { true }
    end

    trait :non_billable do
      billable { false }
      total_amount { nil }
    end

    trait :invoiced do
      invoiced { true }
    end

    trait :today do
      date { Date.current }
    end

    trait :this_week do
      date { Date.current.beginning_of_week + rand(0..6).days }
    end

    trait :this_month do
      date { Date.current.beginning_of_month + rand(0..27).days }
    end

    trait :last_month do
      date { 1.month.ago.to_date }
    end

    trait :with_high_rate do
      hourly_rate { 150.00 }
    end

    trait :full_day do
      hours { 8.0 }
    end

    trait :half_day do
      hours { 4.0 }
    end
  end
end
