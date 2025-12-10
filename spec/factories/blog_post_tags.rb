FactoryBot.define do
  factory :blog_post_tag do
    association :blog_post
    association :blog_tag
  end
end
