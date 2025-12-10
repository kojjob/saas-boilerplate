# frozen_string_literal: true

FactoryBot.define do
  factory :onboarding_progress do
    association :user

    trait :with_client do
      created_client_at { 1.day.ago }
    end

    trait :with_project do
      created_client_at { 2.days.ago }
      created_project_at { 1.day.ago }
    end

    trait :with_invoice do
      created_client_at { 3.days.ago }
      created_project_at { 2.days.ago }
      created_invoice_at { 1.day.ago }
    end

    trait :with_sent_invoice do
      created_client_at { 4.days.ago }
      created_project_at { 3.days.ago }
      created_invoice_at { 2.days.ago }
      sent_invoice_at { 1.day.ago }
    end

    trait :completed do
      created_client_at { 5.days.ago }
      created_project_at { 4.days.ago }
      created_invoice_at { 3.days.ago }
      sent_invoice_at { 2.days.ago }
      completed_at { 1.day.ago }
    end

    trait :dismissed do
      dismissed_at { 1.day.ago }
    end
  end
end
