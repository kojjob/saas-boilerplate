class BlogTag < ApplicationRecord
  # Associations
  has_many :blog_post_tags, dependent: :destroy
  has_many :blog_posts, through: :blog_post_tags

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :popular, -> { order(posts_count: :desc) }
  scope :alphabetical, -> { order(name: :asc) }
  scope :ordered, -> { order(name: :asc) }
  scope :with_posts, -> { where('posts_count > 0') }

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = name.parameterize
    self.slug = base_slug

    # Ensure uniqueness
    counter = 1
    while BlogTag.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
