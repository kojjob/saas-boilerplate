FactoryBot.define do
  factory :blog_tag do
    sequence(:name) { |n| "Tag #{n}" }
    slug { nil } # Let model auto-generate
    description { Faker::Lorem.sentence }
    posts_count { 0 }

    trait :popular do
      posts_count { rand(10..50) }
    end
  end
end
