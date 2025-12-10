FactoryBot.define do
  factory :blog_category do
    sequence(:name) { |n| "Category #{n}" }
    slug { nil } # Let model auto-generate
    description { Faker::Lorem.paragraph }
    meta_title { nil }
    meta_description { nil }
    parent_id { nil }
    position { 0 }
    posts_count { 0 }

    trait :with_meta do
      meta_title { Faker::Lorem.sentence(word_count: 5) }
      meta_description { Faker::Lorem.sentence(word_count: 15) }
    end

    trait :with_parent do
      association :parent, factory: :blog_category
    end
  end
end
