# Stripe Webhooks Setup Guide

This guide covers setting up Stripe webhooks for subscription management in the SaaS Boilerplate.

## Overview

Stripe webhooks are used to keep your application's subscription data in sync with Stripe. When events occur in Stripe (like a subscription being created, updated, or canceled), Stripe sends a POST request to your webhook endpoint.

## Webhook Endpoint

The Pay gem automatically mounts the webhook endpoint at:

```
POST /pay/webhooks/stripe
```

## Required Webhook Events

Configure the following events in your Stripe Dashboard:

### Subscription Events
- `customer.subscription.created` - New subscription activated
- `customer.subscription.updated` - Plan/status changes
- `customer.subscription.deleted` - Subscription canceled
- `customer.subscription.trial_will_end` - Trial ending in 3 days
- `customer.subscription.paused` - Subscription paused
- `customer.subscription.resumed` - Subscription resumed

### Invoice Events
- `invoice.payment_failed` - Payment failed (triggers past_due status)
- `invoice.payment_succeeded` - Payment succeeded (recovers from past_due)

## Local Development Setup

### Option 1: Stripe CLI (Recommended)

1. **Install Stripe CLI**
   ```bash
   # macOS
   brew install stripe/stripe-cli/stripe
   
   # Or download from https://stripe.com/docs/stripe-cli
   ```

2. **Login to Stripe**
   ```bash
   stripe login
   ```

3. **Forward webhooks to your local server**
   ```bash
   stripe listen --forward-to localhost:3000/pay/webhooks/stripe
   ```

4. **Copy the webhook signing secret**
   The CLI will display a webhook signing secret like:
   ```
   > Ready! Your webhook signing secret is whsec_xxxxx
   ```

5. **Add the secret to your credentials**
   ```bash
   bin/rails credentials:edit
   ```
   
   Update the stripe section:
   ```yaml
   stripe:
     secret_key: sk_test_xxxxx
     publishable_key: pk_test_xxxxx
     webhook_secret: whsec_xxxxx  # From stripe listen command
   ```

6. **Restart your Rails server**
   ```bash
   bin/dev
   ```

### Option 2: ngrok (Alternative)

1. **Install ngrok**
   ```bash
   brew install ngrok
   ```

2. **Start ngrok tunnel**
   ```bash
   ngrok http 3000
   ```

3. **Configure webhook in Stripe Dashboard**
   - Go to Developers → Webhooks
   - Add endpoint: `https://your-ngrok-url.ngrok.io/pay/webhooks/stripe`
   - Select the events listed above
   - Copy the signing secret to your credentials

## Production Setup

### 1. Configure Webhook Endpoint in Stripe Dashboard

1. Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click "Add endpoint"
3. Enter your production URL:
   ```
   https://your-domain.com/pay/webhooks/stripe
   ```
4. Select the events listed above
5. Click "Add endpoint"

### 2. Get the Webhook Signing Secret

1. Click on your newly created endpoint
2. Under "Signing secret", click "Reveal"
3. Copy the `whsec_xxx` value

### 3. Add Secret to Production Credentials

```bash
EDITOR=vim bin/rails credentials:edit --environment production
```

```yaml
stripe:
  secret_key: sk_live_xxxxx
  publishable_key: pk_live_xxxxx
  webhook_secret: whsec_xxxxx
```

## Testing Webhooks

### Using Stripe CLI

```bash
# Trigger a specific event
stripe trigger customer.subscription.created

# Trigger with specific data
stripe trigger customer.subscription.updated \
  --override subscription:status=past_due
```

### Using RSpec Tests

```bash
bundle exec rspec spec/models/pay/webhooks/subscription_handler_spec.rb
```

## Event Handling Details

### Subscription Created
When a new subscription is created:
- Account's plan is updated to match the subscription's price
- Subscription status is set (active, trialing, etc.)
- Trial end date is recorded if applicable

### Subscription Updated
When a subscription changes (upgrade, downgrade, status change):
- Account's plan is synced with the new price
- Subscription status is updated
- If status changes to `past_due`, a notification is triggered

### Subscription Deleted
When a subscription is canceled:
- Account is downgraded to the Free plan
- Subscription status is set to `canceled`
- Trial end date is cleared

### Payment Failed
When a payment fails:
- Account's subscription status is set to `past_due`
- A notification is triggered for the payment issue

### Payment Succeeded
When a payment succeeds after being past_due:
- Account's subscription status is restored to `active`

## Webhook Handler Location

The webhook handler is located at:
```
app/models/pay/webhooks/subscription_handler.rb
```

## Troubleshooting

### Webhooks Not Being Received

1. **Check the endpoint URL** - Ensure it matches `/pay/webhooks/stripe`
2. **Verify the signing secret** - Must match in Stripe and your credentials
3. **Check Rails logs** - Look for `[Webhook]` log entries
4. **Verify Stripe CLI is running** - For local development

### Webhook Signature Verification Failed

This usually means the webhook secret doesn't match:
1. Get the correct secret from Stripe CLI or Dashboard
2. Update your credentials
3. Restart your Rails server

### Account Not Updating

1. Check that `Pay::Customer` exists for the account
2. Verify the Plan has the correct `stripe_price_id`
3. Check Rails logs for webhook processing errors

## Monitoring

### Log Entries

The webhook handler logs all events:
```
[Webhook] Processing customer.subscription.created for sub_xxxxx
[Webhook] Account abc123 subscribed to Pro
```

Errors are logged with full context:
```
[Webhook] Error processing customer.subscription.updated: ...
```

### Stripe Dashboard

Monitor webhook delivery in Stripe Dashboard:
1. Go to Developers → Webhooks
2. Click your endpoint
3. View recent deliveries and any failures

## Security Notes

1. **Never commit webhook secrets** - Always use Rails credentials
2. **Verify webhook signatures** - Pay gem handles this automatically
3. **Use HTTPS in production** - Required for webhook endpoints
4. **Monitor failed webhooks** - Set up alerts for repeated failures
