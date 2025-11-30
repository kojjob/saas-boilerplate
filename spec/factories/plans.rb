# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    name { "Pro Plan" }
    sequence(:stripe_price_id) { |n| "price_#{SecureRandom.hex(8)}_#{n}" }
    price_cents { 1999 }
    interval { "month" }
    trial_days { 14 }
    active { true }
    features { [ "Feature 1", "Feature 2", "Feature 3" ] }
    limits { { "users" => 10, "projects" => 100 } }

    trait :free do
      name { "Free Plan" }
      price_cents { 0 }
      trial_days { 0 }
      features { [ "Basic Feature" ] }
      limits { { "users" => 1, "projects" => 3 } }
    end

    trait :starter do
      name { "Starter Plan" }
      price_cents { 999 }
      features { [ "Feature 1", "Feature 2" ] }
      limits { { "users" => 5, "projects" => 25 } }
    end

    trait :pro do
      name { "Pro Plan" }
      price_cents { 2999 }
      features { [ "Feature 1", "Feature 2", "Feature 3", "Priority Support" ] }
      limits { { "users" => 25, "projects" => 500 } }
    end

    trait :enterprise do
      name { "Enterprise Plan" }
      price_cents { 9999 }
      features { [ "All Features", "Dedicated Support", "Custom Integrations", "SLA" ] }
      limits { { "users" => -1, "projects" => -1 } } # -1 means unlimited
    end

    trait :yearly do
      interval { "year" }
      price_cents { 19999 } # Discounted yearly price
    end

    trait :inactive do
      active { false }
    end
  end
end
