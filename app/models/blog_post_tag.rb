class BlogPostTag < ApplicationRecord
  # Associations
  belongs_to :blog_post
  belongs_to :blog_tag, counter_cache: :posts_count

  # Validations
  validates :blog_post_id, uniqueness: { scope: :blog_tag_id }
end
