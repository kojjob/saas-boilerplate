# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'webmock/rspec'
require 'vcr'
require 'database_cleaner/active_record'
require 'with_model'

# Start SimpleCov for code coverage
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Policies', 'app/policies'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'

  minimum_coverage 70
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include Devise test helpers (when we add authentication)
  # config.include Devise::Test::IntegrationHelpers, type: :request
  # config.include Devise::Test::ControllerHelpers, type: :controller

  # Include Pundit test helpers
  config.include Pundit::Matchers

  # Include WithModel for dynamic model testing
  config.extend WithModel

  # Configure request specs to include helpers
  config.include ActionDispatch::TestProcess::FixtureFile

  # Add Capybara DSL to system specs
  config.include Capybara::DSL, type: :system

  # Configure system tests to use headless Chrome
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end

  # Database cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# WebMock configuration
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    'chromedriver.storage.googleapis.com',
    'googlechromelabs.github.io'
  ]
)

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<STRIPE_API_KEY>') { ENV['STRIPE_SECRET_KEY'] }
  config.filter_sensitive_data('<STRIPE_PUBLISHABLE_KEY>') { ENV['STRIPE_PUBLISHABLE_KEY'] }
end
