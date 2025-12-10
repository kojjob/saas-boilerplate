class BlogPost < ApplicationRecord
  # Constants
  WORDS_PER_MINUTE = 200
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  ALLOWED_VIDEO_TYPES = %w[video/mp4 video/webm video/quicktime].freeze
  ALLOWED_AUDIO_TYPES = %w[audio/mpeg audio/wav audio/ogg audio/mp4].freeze

  # Associations
  belongs_to :author, class_name: 'User'
  belongs_to :blog_category, optional: true, counter_cache: :posts_count
  has_many :blog_post_tags, dependent: :destroy
  has_many :blog_tags, through: :blog_post_tags

  # Alias for convenience in views
  alias_method :tags, :blog_tags

  # Active Storage Attachments
  has_one_attached :featured_image do |attachable|
    attachable.variant :thumb, resize_to_fill: [300, 200]
    attachable.variant :medium, resize_to_fill: [600, 400]
    attachable.variant :large, resize_to_fill: [1200, 800]
    attachable.variant :social, resize_to_fill: [1200, 630] # Open Graph
  end

  has_many_attached :images do |attachable|
    attachable.variant :thumb, resize_to_fill: [150, 150]
    attachable.variant :medium, resize_to_limit: [800, 600]
    attachable.variant :large, resize_to_limit: [1400, 1050]
  end

  has_many_attached :videos
  has_many_attached :audio_files
  has_many_attached :documents

  # Enums
  enum :status, { draft: 0, published: 1, scheduled: 2, archived: 3 }

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :excerpt, length: { maximum: 500 }, allow_blank: true

  # Media validations
  validates :featured_image, content_type: ALLOWED_IMAGE_TYPES,
                             size: { less_than: 10.megabytes },
                             if: -> { featured_image.attached? }
  validates :images, content_type: ALLOWED_IMAGE_TYPES,
                     size: { less_than: 10.megabytes },
                     if: -> { images.attached? }
  validates :videos, content_type: ALLOWED_VIDEO_TYPES,
                     size: { less_than: 100.megabytes },
                     if: -> { videos.attached? }
  validates :audio_files, content_type: ALLOWED_AUDIO_TYPES,
                          size: { less_than: 50.megabytes },
                          if: -> { audio_files.attached? }

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

  # Media helper methods
  def has_featured_image?
    featured_image.attached?
  end

  def has_media?
    images.attached? || videos.attached? || audio_files.attached? || documents.attached?
  end

  def media_count
    images.count + videos.count + audio_files.count + documents.count
  end

  def purge_image(image_id)
    images.find(image_id).purge_later
  end

  def purge_video(video_id)
    videos.find(video_id).purge_later
  end

  def purge_audio(audio_id)
    audio_files.find(audio_id).purge_later
  end

  def purge_document(document_id)
    documents.find(document_id).purge_later
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
