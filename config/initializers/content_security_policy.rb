# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   :self, "https://js.stripe.com", "https://hooks.stripe.com"
    policy.connect_src :self, :https, :wss

    # Allow Stripe for payment processing
    policy.script_src  :self, :https, "https://js.stripe.com"

    # Specify URI for violation reports (optional - enable when you have an endpoint)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing the policy in development/test
  # Set to false in production to enforce
  config.content_security_policy_report_only = !Rails.env.production?
end
