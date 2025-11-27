# frozen_string_literal: true

module AuthenticationHelpers
  # Sign in a user for request specs
  def sign_in(user, account: nil)
    session = user.sessions.create!(
      ip_address: '127.0.0.1',
      user_agent: 'RSpec Test'
    )

    # Set session token in cookie
    cookies.signed[:session_token] = session.id

    # Set current account if provided
    if account
      cookies.signed[:current_account_id] = account.id
    elsif user.memberships.any?
      cookies.signed[:current_account_id] = user.memberships.first.account_id
    end

    session
  end

  # Sign out the current user
  def sign_out
    cookies.delete(:session_token)
    cookies.delete(:current_account_id)
  end

  # Create a user with an account and membership
  def create_user_with_account(role: :owner, **user_attributes)
    user = create(:user, **user_attributes)
    account = create(:account)
    create(:membership, user: user, account: account, role: role)
    sign_in(user, account: account)
    { user: user, account: account }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
end
