# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           {
             scope: 'email,profile',
             prompt: 'select_account',
             image_aspect_ratio: 'square',
             image_size: 200,
             access_type: 'offline'
           }

  # GitHub OAuth
  provider :github,
           ENV['GITHUB_CLIENT_ID'],
           ENV['GITHUB_CLIENT_SECRET'],
           {
             scope: 'user:email,read:user'
           }
end

# Configure OmniAuth for better security
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle OAuth failures
OmniAuth.config.on_failure = Proc.new do |env|
  OauthCallbacksController.action(:failure).call(env)
end
