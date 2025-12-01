# frozen_string_literal: true

class Document < ApplicationRecord
  # Active Storage
  has_one_attached :file

  # Associations
  belongs_to :account
  belongs_to :project, optional: true
  belongs_to :uploaded_by, class_name: "User"

  # Enums
  enum :category, {
    general: 0,
    contract: 1,
    proposal: 2,
    receipt: 3,
    photo: 4,
    permit: 5,
    insurance: 6,
    other: 7
  }, default: :general

  # Validations
  validates :name, presence: true
  validate :acceptable_file

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) {
    return all if query.blank?
    where("name ILIKE :query OR description ILIKE :query", query: "%#{query}%")
  }

  # Instance Methods
  def file_type
    return nil unless file.attached?
    file.content_type
  end

  def file_size
    return nil unless file.attached?
    file.byte_size
  end

  def file_size_formatted
    return nil unless file.attached?
    number_to_human_size(file.byte_size)
  end

  def image?
    file.attached? && file.content_type.start_with?("image/")
  end

  def pdf?
    file.attached? && file.content_type == "application/pdf"
  end

  private

  def acceptable_file
    return unless file.attached?

    unless file.blob.byte_size <= 25.megabytes
      errors.add(:file, "is too big (maximum is 25MB)")
    end

    acceptable_types = [
      "image/jpeg", "image/png", "image/gif", "image/webp",
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "text/plain", "text/csv"
    ]

    unless acceptable_types.include?(file.content_type)
      errors.add(:file, "must be an image, PDF, document, or spreadsheet")
    end
  end
end
