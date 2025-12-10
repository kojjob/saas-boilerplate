# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    account
    client { association :client, account: account }
    name { Faker::Company.catch_phrase }
    description { Faker::Lorem.paragraph }
    status { :draft }

    trait :active do
      status { :active }
      start_date { 1.week.ago }
    end

    trait :completed do
      status { :completed }
      start_date { 2.months.ago }
      end_date { 1.week.ago }
    end

    trait :on_hold do
      status { :on_hold }
      start_date { 1.month.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_budget do
      budget { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    end

    trait :with_hourly_rate do
      hourly_rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    trait :with_due_date do
      due_date { 30.days.from_now }
    end

    trait :overdue do
      status { :active }
      start_date { 2.months.ago }
      due_date { 1.week.ago }
    end

    trait :with_address do
      address_line1 { Faker::Address.street_address }
      city { Faker::Address.city }
      state { Faker::Address.state_abbr }
      postal_code { Faker::Address.zip_code }
    end

    trait :with_time_entries do
      after(:create) do |project|
        create_list(:time_entry, 3, project: project, account: project.account, user: project.account.users.first || create(:user))
      end
    end

    trait :with_material_entries do
      after(:create) do |project|
        create_list(:material_entry, 3, project: project, account: project.account, user: project.account.users.first || create(:user))
      end
    end
  end
end
