# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    association :account
    association :uploaded_by, factory: :user
    project { nil }
    name { Faker::File.file_name }
    description { Faker::Lorem.sentence }
    category { :general }

    trait :with_project do
      association :project
    end

    trait :contract do
      category { :contract }
      name { "Contract_#{Faker::Alphanumeric.alphanumeric(number: 8)}.pdf" }
    end

    trait :proposal do
      category { :proposal }
      name { "Proposal_#{Faker::Alphanumeric.alphanumeric(number: 8)}.pdf" }
    end

    trait :receipt do
      category { :receipt }
      name { "Receipt_#{Faker::Alphanumeric.alphanumeric(number: 8)}.pdf" }
    end

    trait :photo do
      category { :photo }
      name { "Photo_#{Faker::Alphanumeric.alphanumeric(number: 8)}.jpg" }
    end

    trait :permit do
      category { :permit }
      name { "Permit_#{Faker::Alphanumeric.alphanumeric(number: 8)}.pdf" }
    end

    trait :insurance do
      category { :insurance }
      name { "Insurance_#{Faker::Alphanumeric.alphanumeric(number: 8)}.pdf" }
    end

    trait :with_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Test file content"),
          filename: document.name,
          content_type: "text/plain"
        )
      end
    end

    trait :with_pdf do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("%PDF-1.4 Test PDF content"),
          filename: "#{document.name}.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_image do
      after(:build) do |document|
        # Create a simple valid 1x1 PNG
        png_data = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
        document.file.attach(
          io: StringIO.new(png_data),
          filename: "#{document.name}.png",
          content_type: "image/png"
        )
      end
    end
  end
end
