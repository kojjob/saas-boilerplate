# frozen_string_literal: true

# Authentication concern provides session-based authentication
# using Rails 8's built-in authentication patterns
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
  end

  private

  # Returns the currently signed in user
  def current_user
    @current_user ||= current_session&.user
  end

  # Returns true if a user is signed in
  def signed_in?
    current_user.present?
  end

  # Returns the current session record
  def current_session
    return @current_session if defined?(@current_session)

    @current_session = Session.find_by(id: session[:user_session_id])
  end

  # Signs in the given user by creating a new session
  def sign_in(user)
    reset_session
    session_record = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    session[:user_session_id] = session_record.id
    @current_session = session_record
    @current_user = user

    # Set the tenant to user's first account for multi-tenancy
    if user.accounts.any?
      session[:current_account_id] = user.accounts.first.id
    end
  end

  # Signs out the current user by destroying their session
  def sign_out
    current_session&.destroy
    reset_session
    @current_session = nil
    @current_user = nil
  end

  # Requires authentication, redirects to sign in if not authenticated
  def authenticate_user!
    return if signed_in?

    store_location_for_redirect
    redirect_to sign_in_path, alert: "Please sign in to continue."
  end

  # Stores the current URL for redirect after sign in
  def store_location_for_redirect
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  # Returns the stored location or a default path
  def stored_location_or(default)
    session.delete(:return_to) || default
  end
end
