# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Lint factories before running tests (optional, can slow down test suite)
  config.before(:suite) do
    # Uncomment to validate all factories before tests run
    # FactoryBot.lint
  end
end
