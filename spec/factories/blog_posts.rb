FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Blog Post #{n}" }
    slug { nil } # Let model auto-generate
    excerpt { Faker::Lorem.paragraph(sentence_count: 2) }
    content { Faker::Lorem.paragraphs(number: 5).join("\n\n") }
    meta_title { nil }
    meta_description { nil }
    featured_image_url { nil }
    association :author, factory: :user
    blog_category { nil }
    status { :draft }
    published_at { nil }
    reading_time { 0 } # Let model calculate
    views_count { 0 }
    featured { false }
    allow_comments { true }

    trait :draft do
      status { :draft }
      published_at { nil }
    end

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :scheduled do
      status { :scheduled }
      published_at { 1.week.from_now }
    end

    trait :archived do
      status { :archived }
      published_at { 1.month.ago }
    end

    trait :featured do
      featured { true }
    end

    trait :with_category do
      association :blog_category
    end

    trait :with_tags do
      after(:create) do |post|
        create_list(:blog_tag, 3).each do |tag|
          create(:blog_post_tag, blog_post: post, blog_tag: tag)
        end
      end
    end

    trait :with_meta do
      meta_title { Faker::Lorem.sentence(word_count: 6) }
      meta_description { Faker::Lorem.sentence(word_count: 20) }
    end

    trait :popular do
      views_count { rand(100..1000) }
    end
  end
end
