# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    association :participant_1, factory: :user
    association :participant_2, factory: :user
    account { nil }

    trait :with_messages do
      after(:create) do |conversation|
        create_list(:message, 3,
          conversation: conversation,
          sender: conversation.participant_1,
          recipient: conversation.participant_2)
      end
    end

    trait :with_account do
      association :account
    end
  end
end
