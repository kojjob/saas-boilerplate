# frozen_string_literal: true

FactoryBot.define do
  factory :onboarding_progress do
    association :user

    client_created { false }
    project_created { false }
    invoice_created { false }
    invoice_sent { false }
    dismissed { false }

    trait :with_client_step do
      client_created { true }
      client_created_at { Time.current }
    end

    trait :with_project_step do
      with_client_step
      project_created { true }
      project_created_at { Time.current }
    end

    trait :with_invoice_step do
      with_project_step
      invoice_created { true }
      invoice_created_at { Time.current }
    end

    trait :completed do
      with_invoice_step
      invoice_sent { true }
      invoice_sent_at { Time.current }
    end

    trait :dismissed do
      dismissed { true }
      dismissed_at { Time.current }
    end
  end
end
