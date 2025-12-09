# frozen_string_literal: true

FactoryBot.define do
  factory :material_entry do
    account
    project { association :project, account: account }
    user { association :user }
    date { Date.current }
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    quantity { Faker::Number.between(from: 1, to: 10) }
    unit { %w[feet inches meters pieces boxes bags rolls sheets].sample }
    unit_cost { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    markup_percentage { 15.0 }
    billable { true }
    invoiced { false }

    trait :non_billable do
      billable { false }
      markup_percentage { 0 }
      total_amount { 0 }
    end

    trait :invoiced do
      invoiced { true }
    end

    trait :no_markup do
      markup_percentage { 0 }
    end

    trait :high_markup do
      markup_percentage { 50.0 }
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

    trait :expensive do
      unit_cost { 500.00 }
      quantity { 5 }
    end
  end
end
