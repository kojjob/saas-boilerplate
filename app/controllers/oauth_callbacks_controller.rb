# frozen_string_literal: true

class OauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :google_oauth2, :github, :failure ]
  before_action :redirect_if_signed_in, only: [ :create, :google_oauth2, :github ]

  # Unified OAuth callback handler (used with auth/:provider/callback route)
  def create
    handle_oauth_callback
  end

  def google_oauth2
    handle_oauth_callback
  end

  def github
    handle_oauth_callback
  end

  def failure
    error_message = params[:message] || "Authentication failed"
    redirect_to sign_in_path, alert: "OAuth authentication failed: #{error_message}"
  end

  private

  def handle_oauth_callback
    auth = request.env["omniauth.auth"]

    # Handle invalid credentials or failure
    if auth.nil? || auth == :invalid_credentials
      return redirect_to sign_in_path, alert: "OAuth authentication failed. Please try again."
    end

    # Validate email presence (required for GitHub)
    email = auth.info&.email
    if email.blank?
      return redirect_to sign_in_path, alert: "Could not retrieve email from your account. Please ensure your email is public or use a different sign-in method."
    end

    # Find or create user
    result = find_or_create_user_from_oauth(auth)

    if result[:success]
      sign_in(result[:user])
      redirect_to dashboard_path, notice: "Successfully signed in with your account!"
    else
      redirect_to sign_in_path, alert: result[:error]
    end
  end

  def find_or_create_user_from_oauth(auth)
    # First, try to find user by OAuth provider + uid
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return { success: true, user: user } if user.present?

    # Next, try to find user by email and link OAuth
    email = auth.info.email.downcase.strip
    user = User.find_by(email: email)

    if user.present?
      # Link OAuth to existing user
      user.update!(
        provider: auth.provider,
        uid: auth.uid,
        avatar_url: auth.info.image
      )
      return { success: true, user: user }
    end

    # Create new user with OAuth
    create_user_from_oauth(auth)
  end

  def create_user_from_oauth(auth)
    first_name, last_name = extract_names(auth)

    ActiveRecord::Base.transaction do
      # Create user (OAuth users get a random secure password)
      random_password = SecureRandom.hex(32)
      user = User.create!(
        email: auth.info.email,
        first_name: first_name,
        last_name: last_name,
        provider: auth.provider,
        uid: auth.uid,
        avatar_url: auth.info.image,
        password: random_password,
        password_confirmation: random_password,
        confirmed_at: Time.current # OAuth users are auto-confirmed
      )

      # Create account for the user
      account_name = "#{first_name}'s Account"
      account = Account.create!(
        name: account_name,
        slug: generate_unique_slug(account_name)
      )

      # Create membership as owner
      Membership.create!(
        user: user,
        account: account,
        role: "owner",
        accepted_at: Time.current
      )

      { success: true, user: user }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: "Failed to create account: #{e.message}" }
  end

  def extract_names(auth)
    # Try to get first_name and last_name directly
    first_name = auth.info.first_name
    last_name = auth.info.last_name

    # Fallback: parse name field
    if first_name.blank? || last_name.blank?
      full_name = auth.info.name || auth.info.nickname || "User"
      name_parts = full_name.split(" ")

      first_name = name_parts.first || "User"
      last_name = name_parts[1..].join(" ").presence || "Account"
    end

    [ first_name, last_name ]
  end

  def generate_unique_slug(name)
    base_slug = name.parameterize
    slug = base_slug
    counter = 1

    while Account.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end

  def redirect_if_signed_in
    redirect_to dashboard_path if signed_in?
  end
end
