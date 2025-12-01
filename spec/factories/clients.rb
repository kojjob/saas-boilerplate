# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    association :account
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    company { Faker::Company.name }
    status { :active }
    notes { Faker::Lorem.paragraph }

    trait :with_address do
      address_line1 { Faker::Address.street_address }
      address_line2 { Faker::Address.secondary_address }
      city { Faker::Address.city }
      state { Faker::Address.state_abbr }
      postal_code { Faker::Address.zip_code }
      country { "USA" }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_projects do
      after(:create) do |client|
        create_list(:project, 2, client: client, account: client.account)
      end
    end

    trait :with_invoices do
      after(:create) do |client|
        create_list(:invoice, 2, client: client, account: client.account)
      end
    end
  end
end
