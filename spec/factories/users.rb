# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :confirmed do
      confirmed_at { Time.current }
      confirmation_token { nil }
    end

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_token { SecureRandom.urlsafe_base64 }
    end

    trait :with_reset_token do
      reset_password_token { SecureRandom.urlsafe_base64 }
      reset_password_sent_at { Time.current }
    end

    trait :with_expired_reset_token do
      reset_password_token { SecureRandom.urlsafe_base64 }
      reset_password_sent_at { 3.hours.ago }
    end

    trait :with_account do
      transient do
        account { nil }
        role { :member }
      end

      after(:create) do |user, evaluator|
        account = evaluator.account || create(:account)
        create(:membership, user: user, account: account, role: evaluator.role)
      end
    end

    trait :owner do
      after(:create) do |user|
        account = create(:account)
        create(:membership, :owner, user: user, account: account)
      end
    end

    # Site-wide admin (can access /admin dashboard)
    trait :admin do
      site_admin { true }

      after(:create) do |user|
        account = create(:account)
        create(:membership, :owner, user: user, account: account)
      end
    end

    # Account-level admin role (admin of a specific account, not site-wide)
    trait :account_admin do
      after(:create) do |user|
        account = create(:account)
        create(:membership, :admin, user: user, account: account)
      end
    end

    trait :oauth_google do
      provider { 'google_oauth2' }
      uid { SecureRandom.uuid }
      avatar_url { 'https://lh3.googleusercontent.com/photo.jpg' }
    end

    trait :oauth_github do
      provider { 'github' }
      uid { SecureRandom.uuid }
      avatar_url { 'https://avatars.githubusercontent.com/u/123456' }
    end
  end
end
