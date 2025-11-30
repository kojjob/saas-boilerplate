# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :conversation
    association :sender, factory: :user
    association :recipient, factory: :user
    body { Faker::Lorem.paragraph(sentence_count: 2) }
    read_at { nil }
    account { nil }

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :with_account do
      association :account
    end
  end
end
