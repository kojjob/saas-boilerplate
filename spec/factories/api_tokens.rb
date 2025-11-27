# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    association :user
    token { SecureRandom.hex(32) }
    expires_at { 30.days.from_now }
    revoked_at { nil }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end
  end
end
