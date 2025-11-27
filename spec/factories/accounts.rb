# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    sequence(:slug) { |n| "company-#{n}" }
    subdomain { Faker::Internet.slug(glue: '').gsub(/[^a-z0-9]/i, '') }
    settings { {} }
    subscription_status { 'trialing' }
    trial_ends_at { 14.days.from_now }

    trait :active do
      subscription_status { 'active' }
      trial_ends_at { nil }
    end

    trait :trial_expired do
      subscription_status { 'trialing' }
      trial_ends_at { 1.day.ago }
    end

    trait :canceled do
      subscription_status { 'canceled' }
      trial_ends_at { nil }
    end

    trait :past_due do
      subscription_status { 'past_due' }
    end

    trait :with_owner do
      after(:create) do |account|
        create(:membership, :owner, account: account)
      end
    end

    trait :with_members do
      transient do
        members_count { 3 }
      end

      after(:create) do |account, evaluator|
        create(:membership, :owner, account: account)
        create_list(:membership, evaluator.members_count, account: account)
      end
    end
  end
end
