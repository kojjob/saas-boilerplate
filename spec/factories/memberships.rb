# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    association :user
    association :account
    role { :member }
    accepted_at { Time.current }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end

    trait :member do
      role { :member }
    end

    trait :guest do
      role { :guest }
    end

    trait :invited do
      user { nil }
      invitation_email { Faker::Internet.email }
      invitation_token { SecureRandom.urlsafe_base64(32) }
      invited_at { Time.current }
      accepted_at { nil }
      association :invited_by, factory: :user
    end

    trait :accepted do
      accepted_at { Time.current }
      invitation_token { nil }
    end

    trait :expired_invitation do
      user { nil }
      invitation_email { Faker::Internet.email }
      invitation_token { SecureRandom.urlsafe_base64(32) }
      invited_at { 8.days.ago }
      accepted_at { nil }
    end
  end
end
