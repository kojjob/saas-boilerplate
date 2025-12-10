# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding Plans..."

# Helper to get Stripe price ID from credentials or ENV
def stripe_price_id(key, fallback)
  Rails.application.credentials.dig(:stripe, :prices, key) ||
    ENV.fetch("STRIPE_#{key.to_s.upcase}_PRICE_ID", fallback)
end

# Define plans with features and limits
plans_data = [
  {
    name: "Free",
    stripe_price_id: "price_free_plan",
    price_cents: 0,
    trial_days: 0,
    interval: "month",
    description: "Perfect for getting started with basic project management",
    features: [
      "Up to 5 clients",
      "Up to 10 projects",
      "Up to 25 invoices/month",
      "Basic time tracking",
      "Email support"
    ],
    limits: {
      "clients" => 5,
      "projects" => 10,
      "invoices_per_month" => 25,
      "documents" => 50,
      "team_members" => 1
    },
    active: true,
    sort_order: 1
  },
  {
    name: "Pro",
    stripe_price_id: stripe_price_id(:pro_monthly, "price_pro_monthly"),
    price_cents: 2900, # $29.00/month
    trial_days: 14,
    interval: "month",
    description: "Best for growing contractors who need full functionality",
    features: [
      "Unlimited clients",
      "Unlimited projects",
      "Unlimited invoices",
      "Time & materials tracking",
      "Document storage (5GB)",
      "Custom branding",
      "Priority email support",
      "Invoice reminders",
      "Payment tracking"
    ],
    limits: {
      "clients" => -1, # -1 means unlimited
      "projects" => -1,
      "invoices_per_month" => -1,
      "documents" => 500,
      "team_members" => 5,
      "storage_gb" => 5
    },
    active: true,
    sort_order: 2
  },
  {
    name: "Pro (Yearly)",
    stripe_price_id: stripe_price_id(:pro_yearly, "price_pro_yearly"),
    price_cents: 29000, # $290.00/year (save $58/year)
    trial_days: 14,
    interval: "year",
    description: "Pro plan with annual billing - save 2 months!",
    features: [
      "Unlimited clients",
      "Unlimited projects",
      "Unlimited invoices",
      "Time & materials tracking",
      "Document storage (5GB)",
      "Custom branding",
      "Priority email support",
      "Invoice reminders",
      "Payment tracking",
      "Save $58/year"
    ],
    limits: {
      "clients" => -1,
      "projects" => -1,
      "invoices_per_month" => -1,
      "documents" => 500,
      "team_members" => 5,
      "storage_gb" => 5
    },
    active: true,
    sort_order: 3
  },
  {
    name: "Enterprise",
    stripe_price_id: stripe_price_id(:enterprise_monthly, "price_enterprise_monthly"),
    price_cents: 9900, # $99.00/month
    trial_days: 14,
    interval: "month",
    description: "For established teams requiring advanced features and support",
    features: [
      "Everything in Pro",
      "Unlimited team members",
      "Document storage (50GB)",
      "API access",
      "Custom integrations",
      "Dedicated account manager",
      "Phone support",
      "Advanced reporting",
      "Multi-location support",
      "White-label options"
    ],
    limits: {
      "clients" => -1,
      "projects" => -1,
      "invoices_per_month" => -1,
      "documents" => -1,
      "team_members" => -1,
      "storage_gb" => 50
    },
    active: true,
    sort_order: 4
  },
  {
    name: "Enterprise (Yearly)",
    stripe_price_id: stripe_price_id(:enterprise_yearly, "price_enterprise_yearly"),
    price_cents: 99000, # $990.00/year (save $198/year)
    trial_days: 14,
    interval: "year",
    description: "Enterprise plan with annual billing - save 2 months!",
    features: [
      "Everything in Pro",
      "Unlimited team members",
      "Document storage (50GB)",
      "API access",
      "Custom integrations",
      "Dedicated account manager",
      "Phone support",
      "Advanced reporting",
      "Multi-location support",
      "White-label options",
      "Save $198/year"
    ],
    limits: {
      "clients" => -1,
      "projects" => -1,
      "invoices_per_month" => -1,
      "documents" => -1,
      "team_members" => -1,
      "storage_gb" => 50
    },
    active: true,
    sort_order: 5
  }
]

plans_data.each do |plan_attrs|
  plan = Plan.find_or_initialize_by(stripe_price_id: plan_attrs[:stripe_price_id])
  plan.assign_attributes(plan_attrs)
  plan.save!
  puts "  #{plan.new_record? ? 'Created' : 'Updated'} plan: #{plan.name} - #{plan.formatted_price}/#{plan.interval_label}"
end

puts "✓ Seeded #{Plan.count} plans"

# ==================================
# Create Site Admin User
# ==================================
puts "\nSeeding Site Admin User..."

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin_user = User.find_or_initialize_by(email: admin_email)
admin_user.assign_attributes(
  first_name: "Site",
  last_name: "Admin",
  password: admin_password,
  password_confirmation: admin_password,
  site_admin: true,
  confirmed_at: Time.current
)

if admin_user.save
  puts "  #{admin_user.previously_new_record? ? 'Created' : 'Updated'} site admin: #{admin_user.email}"
  puts "  Password: #{admin_password}" if admin_user.previously_new_record?
else
  puts "  ✗ Failed to create admin: #{admin_user.errors.full_messages.join(', ')}"
end

# Create an account for the admin user if they don't have one
if admin_user.persisted? && admin_user.accounts.empty?
  account = Account.create!(name: "Admin Account")
  Membership.create!(user: admin_user, account: account, role: :owner)
  puts "  Created account: #{account.name}"
end

puts "✓ Site admin seeded"
