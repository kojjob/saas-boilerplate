# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.paragraph }
    notification_type { :info }
    read_at { nil }

    trait :with_account do
      association :account
    end

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :info do
      notification_type { :info }
    end

    trait :success do
      notification_type { :success }
    end

    trait :warning do
      notification_type { :warning }
    end

    trait :error do
      notification_type { :error }
    end
  end
end
