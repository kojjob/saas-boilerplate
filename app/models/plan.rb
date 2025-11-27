# frozen_string_literal: true

class Plan < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :stripe_price_id, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :trial_days, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, inclusion: { in: %w[month year] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :paid, -> { where("price_cents > 0") }
  scope :free, -> { where(price_cents: 0) }
  scope :monthly, -> { where(interval: "month") }
  scope :yearly, -> { where(interval: "year") }
  scope :sorted, -> { order(sort_order: :asc, price_cents: :asc) }

  # Instance methods
  def price
    price_cents / 100.0
  end

  def free?
    price_cents.zero?
  end

  def formatted_price
    return "Free" if free?

    "$#{format('%.2f', price)}"
  end

  def interval_label
    case interval
    when "month" then "monthly"
    when "year" then "yearly"
    else interval
    end
  end

  def yearly_savings
    return 0 unless interval == "year"

    # Calculate savings compared to monthly
    monthly_plan = Plan.active.monthly.where("price_cents > 0").first
    return 0 unless monthly_plan

    monthly_yearly_cost = monthly_plan.price_cents * 12
    savings = monthly_yearly_cost - price_cents
    (savings / 100.0).round(2)
  end

  def feature_list
    features.is_a?(Array) ? features : []
  end

  def limit_for(resource)
    limits.is_a?(Hash) ? limits[resource.to_s] : nil
  end

  def unlimited?(resource)
    limit_for(resource) == -1
  end
end
