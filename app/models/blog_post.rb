class BlogPost < ApplicationRecord
  # Constants
  WORDS_PER_MINUTE = 200

  # Associations
  belongs_to :author, class_name: 'User'
  belongs_to :blog_category, optional: true, counter_cache: :posts_count
  has_many :blog_post_tags, dependent: :destroy
  has_many :blog_tags, through: :blog_post_tags

  # Alias for convenience in views
  alias_method :tags, :blog_tags

  # Enums
  enum :status, { draft: 0, published: 1, scheduled: 2, archived: 3 }

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_save :calculate_reading_time

  # Scopes
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category_id) { where(blog_category_id: category_id) }
  scope :by_tag, ->(tag_id) { joins(:blog_post_tags).where(blog_post_tags: { blog_tag_id: tag_id }) }
  scope :search, ->(query) {
    where('title ILIKE :q OR content ILIKE :q', q: "%#{query}%")
  }

  # Instance methods
  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def unpublish!
    update!(status: :draft)
  end

  def increment_views!
    increment!(:views_count)
  end

  def meta_title_or_title
    meta_title.presence || title
  end

  def excerpt_or_truncated_content
    return excerpt if excerpt.present?
    content.to_s.truncate(160, separator: ' ')
  end

  def to_param
    slug
  end

  def previous_post
    BlogPost.published
            .where('published_at < ?', published_at)
            .order(published_at: :desc)
            .first
  end

  def next_post
    BlogPost.published
            .where('published_at > ?', published_at)
            .order(published_at: :asc)
            .first
  end

  private

  def generate_slug
    base_slug = title.parameterize
    self.slug = base_slug

    # Ensure uniqueness
    counter = 1
    while BlogPost.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def calculate_reading_time
    return unless content.present?
    word_count = content.split.size
    self.reading_time = [ (word_count.to_f / WORDS_PER_MINUTE).ceil, 1 ].max
  end
end
