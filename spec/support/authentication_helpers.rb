# frozen_string_literal: true

module AuthenticationHelpers
  # Sign in a user for request specs
  def sign_in(user, account: nil)
    # Ensure user has the default password for test
    user.update(password: 'password123') unless user.authenticate('password123')

    # Actually sign in via the sign-in endpoint
    # The session will store the account_id which will be restored on subsequent requests
    post sign_in_path, params: {
      email: user.email,
      password: 'password123'
    }
  end

  # Sign out the current user
  def sign_out
    delete sign_out_path
  end

  # Create a user with an account and membership
  def create_user_with_account(role: :owner, **user_attributes)
    user = create(:user, :confirmed, **user_attributes)
    account = create(:account)
    create(:membership, user: user, account: account, role: role)
    sign_in(user, account: account)
    { user: user, account: account }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system

  # Reset tenant after each test
  config.after(:each) do
    ActsAsTenant.current_tenant = nil
  end
end
