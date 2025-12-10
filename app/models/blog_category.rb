class BlogCategory < ApplicationRecord
  # Associations
  has_many :blog_posts, dependent: :nullify
  belongs_to :parent, class_name: 'BlogCategory', optional: true
  has_many :children, class_name: 'BlogCategory', foreign_key: :parent_id, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :meta_title, length: { maximum: 70 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :with_posts, -> { where('posts_count > 0') }

  # Instance methods
  def has_children?
    children.exists?
  end

  def meta_title_or_name
    meta_title.presence || name
  end

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = name.parameterize
    self.slug = base_slug

    # Ensure uniqueness
    counter = 1
    while BlogCategory.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
