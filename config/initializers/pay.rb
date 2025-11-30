# frozen_string_literal: true

# Configure Stripe API key from Rails credentials
Rails.configuration.stripe = {
  secret_key: Rails.application.credentials.dig(:stripe, :secret_key),
  publishable_key: Rails.application.credentials.dig(:stripe, :publishable_key),
  webhook_secret: Rails.application.credentials.dig(:stripe, :webhook_secret)
}

Pay.setup do |config|
  # For use in the receipt/refund/renewal mailers
  config.business_name = "SaaS Boilerplate"
  config.business_address = "123 Main Street"
  config.application_name = "SaaS Boilerplate"
  config.support_email = "support@example.com"

  # Stripe configuration
  config.default_product_name = "SaaS Boilerplate"
  config.default_plan_name = "default"

  # Enable or disable specific payment processors
  config.enabled_processors = [ :stripe ]

  # Send emails for receipts/invoices
  config.send_emails = false # Disable emails in development/test
end

# Set Stripe API key after Pay is configured
Rails.application.config.after_initialize do
  if Rails.configuration.stripe[:secret_key].present?
    Stripe.api_key = Rails.configuration.stripe[:secret_key]
  end
end

# Register webhook handlers for subscription events
# These handlers update our Account model when Stripe subscription status changes
Rails.application.config.to_prepare do
  subscription_handler = Pay::Webhooks::SubscriptionHandler.new

  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.created", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.updated", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.deleted", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.trial_will_end", subscription_handler)
end
