# frozen_string_literal: true

FactoryBot.define do
  factory :expense do
    association :account
    description { Faker::Commerce.product_name }
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    currency { "USD" }
    category { :software }
    expense_date { Faker::Date.backward(days: 30) }

    trait :with_vendor do
      vendor { Faker::Company.name }
    end

    trait :with_notes do
      notes { Faker::Lorem.paragraph }
    end

    trait :billable do
      billable { true }
    end

    trait :reimbursable do
      reimbursable { true }
    end

    trait :with_receipt do
      after(:build) do |expense|
        expense.receipt.attach(
          io: StringIO.new("fake receipt content"),
          filename: "receipt.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_project do
      association :project
    end

    trait :with_client do
      association :client
    end

    trait :software do
      category { :software }
    end

    trait :hardware do
      category { :hardware }
    end

    trait :travel do
      category { :travel }
    end

    trait :meals do
      category { :meals }
    end

    trait :office do
      category { :office }
    end

    trait :professional_services do
      category { :professional_services }
    end

    trait :marketing do
      category { :marketing }
    end

    trait :utilities do
      category { :utilities }
    end

    trait :subscriptions do
      category { :subscriptions }
    end

    trait :other do
      category { :other }
    end

    trait :euro do
      currency { "EUR" }
    end

    trait :gbp do
      currency { "GBP" }
    end
  end
end
