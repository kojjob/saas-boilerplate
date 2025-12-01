# frozen_string_literal: true

FactoryBot.define do
  factory :alert do
    association :account
    alert_type { "system_notification" }
    severity { :info }
    status { :pending }
    title { Faker::Lorem.sentence(word_count: 4) }
    message { Faker::Lorem.paragraph }
    metadata { {} }

    trait :with_alertable do
      association :alertable, factory: :invoice
    end

    trait :info do
      severity { :info }
    end

    trait :warning do
      severity { :warning }
    end

    trait :error do
      severity { :error }
    end

    trait :critical do
      severity { :critical }
    end

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :failed do
      status { :failed }
      error_message { "Failed to send notification" }
    end

    trait :acknowledged do
      status { :acknowledged }
      acknowledged_at { Time.current }
    end

    trait :payment_alert do
      alert_type { "payment_received" }
      title { "Payment Received" }
      message { "A payment has been received for invoice #12345" }
    end

    trait :invoice_alert do
      alert_type { "invoice_overdue" }
      title { "Invoice Overdue" }
      message { "Invoice #12345 is now overdue" }
      severity { :warning }
    end

    trait :system_alert do
      alert_type { "system_notification" }
      title { "System Notification" }
    end
  end
end
