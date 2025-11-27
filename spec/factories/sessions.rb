# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    association :user
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    last_active_at { Time.current }

    trait :expired do
      created_at { 31.days.ago }
    end

    trait :mobile do
      user_agent { 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1' }
    end

    trait :desktop do
      user_agent { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36' }
    end
  end
end
