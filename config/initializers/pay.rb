# frozen_string_literal: true

# Configure Stripe API key from Rails credentials
Rails.configuration.stripe = {
  secret_key: Rails.application.credentials.dig(:stripe, :secret_key),
  publishable_key: Rails.application.credentials.dig(:stripe, :publishable_key),
  webhook_secret: Rails.application.credentials.dig(:stripe, :webhook_secret)
}

# Set Stripe API key immediately (before Pay.setup)
if Rails.configuration.stripe[:secret_key].present?
  Stripe.api_key = Rails.configuration.stripe[:secret_key]
end

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

# Also ensure Stripe API key is set after all initializers
Rails.application.config.after_initialize do
  if Rails.configuration.stripe[:secret_key].present? && Stripe.api_key.blank?
    Stripe.api_key = Rails.configuration.stripe[:secret_key]
  end
end

# Register webhook handlers for Stripe events
# These handlers update our Account model when Stripe subscription status changes
# and mark invoices as paid when payments are completed via Checkout
#
# Webhook URL: https://your-domain.com/pay/webhooks/stripe
# Required Stripe webhook events to configure:
#
# Subscription events:
# - customer.subscription.created
# - customer.subscription.updated
# - customer.subscription.deleted
# - customer.subscription.trial_will_end
# - customer.subscription.paused
# - customer.subscription.resumed
# - invoice.payment_failed
# - invoice.payment_succeeded
#
# Invoice payment events (for one-time invoice payments):
# - checkout.session.completed
# - payment_intent.succeeded
#
Rails.application.config.to_prepare do
  subscription_handler = Pay::Webhooks::SubscriptionHandler.new

  # Subscription lifecycle events
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.created", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.updated", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.deleted", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.trial_will_end", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.paused", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.resumed", subscription_handler)

  # Invoice/payment events (subscription-related)
  Pay::Webhooks.delegator.subscribe("stripe.invoice.payment_failed", subscription_handler)
  Pay::Webhooks.delegator.subscribe("stripe.invoice.payment_succeeded", subscription_handler)

  # Invoice payment handler for one-time invoice payments via Checkout
  # This handles payments made through the public invoice payment page
  invoice_payment_handler = Pay::Webhooks::InvoicePaymentHandler.new
  Pay::Webhooks.delegator.subscribe("stripe.checkout.session.completed", invoice_payment_handler)
  Pay::Webhooks.delegator.subscribe("stripe.payment_intent.succeeded", invoice_payment_handler)
end
