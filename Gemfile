source "https://rubygems.org"

ruby "3.4.3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# ============================================
# SaaS Core Gems
# ============================================

# Multi-tenancy - Row-level tenant scoping
gem "acts_as_tenant", "~> 1.0"

# Authorization - Policy-based access control
gem "pundit", "~> 2.4"

# Billing - Stripe subscription management
gem "pay", "~> 11.4"
gem "stripe", "~> 18.0"

# Audit logging - Version tracking for models
# Note: paper_trail ~> 16.0 is not compatible with Rails 8.1
# Using audited gem instead which has better Rails 8 support
gem "audited", "~> 5.6"

# Pagination
gem "pagy", "~> 9.3"

# OAuth providers
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection"
gem "omniauth-google-oauth2"
gem "omniauth-github"

# API
gem "rack-cors"
gem "jwt"

# Error tracking
gem "sentry-ruby"
gem "sentry-rails"

# Rate limiting
gem "rack-attack"

# Soft deletes
gem "discard", "~> 1.4"

# PDF Generation - HTML to PDF using Chrome/Puppeteer
gem "grover"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing framework
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "pundit-matchers"
  gem "with_model"  # For testing dynamic model concerns
end

group :test do
  # System testing
  gem "capybara"
  gem "selenium-webdriver"

  # Test utilities
  gem "webmock"
  gem "vcr"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"

  # Time manipulation for tests
  gem "timecop"

  # PDF testing
  gem "pdf-inspector", require: "pdf/inspector"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # N+1 query detection
  gem "bullet"

  # Better error pages
  gem "better_errors"
  gem "binding_of_caller"

  # Annotate models with schema info
  gem "annotate"

  # Security analysis
  gem "rails_best_practices"
end
