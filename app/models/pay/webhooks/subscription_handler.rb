# frozen_string_literal: true

module Pay
  module Webhooks
    # Handles Stripe subscription webhook events to keep Account records in sync
    #
    # Supported events:
    # - customer.subscription.created - New subscription created
    # - customer.subscription.updated - Subscription plan/status changed
    # - customer.subscription.deleted - Subscription canceled
    # - customer.subscription.trial_will_end - Trial ending soon (3 days)
    # - customer.subscription.paused - Subscription paused
    # - customer.subscription.resumed - Subscription resumed
    # - invoice.payment_failed - Payment failed (triggers past_due)
    # - invoice.payment_succeeded - Payment succeeded
    #
    class SubscriptionHandler
      def call(event)
        object = event.data.object
        return unless object

        Rails.logger.info "[Webhook] Processing #{event.type} for #{object.try(:id) || object.try(:customer)}"

        case event.type
        when "customer.subscription.created"
          handle_subscription_created(object)
        when "customer.subscription.updated"
          handle_subscription_updated(object)
        when "customer.subscription.deleted"
          handle_subscription_deleted(object)
        when "customer.subscription.trial_will_end"
          handle_trial_ending(object)
        when "customer.subscription.paused"
          handle_subscription_paused(object)
        when "customer.subscription.resumed"
          handle_subscription_resumed(object)
        when "invoice.payment_failed"
          handle_payment_failed(object)
        when "invoice.payment_succeeded"
          handle_payment_succeeded(object)
        end
      rescue StandardError => e
        Rails.logger.error "[Webhook] Error processing #{event.type}: #{e.message}"
        Rails.logger.error e.backtrace.first(10).join("\n")
        raise # Re-raise to let Pay gem handle retry logic
      end

      private

      def handle_subscription_created(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        plan = find_plan_from_subscription(subscription)

        account.update!(
          plan: plan,
          subscription_status: map_stripe_status(subscription.status),
          trial_ends_at: parse_timestamp(subscription.trial_end)
        )

        Rails.logger.info "[Webhook] Account #{account.id} subscribed to #{plan&.name || 'unknown plan'}"
      end

      def handle_subscription_updated(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        plan = find_plan_from_subscription(subscription)
        previous_status = account.subscription_status
        new_status = map_stripe_status(subscription.status)

        account.update!(
          plan: plan,
          subscription_status: new_status,
          trial_ends_at: parse_timestamp(subscription.trial_end)
        )

        Rails.logger.info "[Webhook] Account #{account.id} subscription updated: #{previous_status} -> #{new_status}"

        # Notify if downgraded or status changed significantly
        if previous_status != new_status && new_status == "past_due"
          notify_payment_issue(account)
        end
      end

      def handle_subscription_deleted(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        free_plan = Plan.free_plan

        account.update!(
          plan: free_plan,
          subscription_status: "canceled",
          trial_ends_at: nil
        )

        Rails.logger.info "[Webhook] Account #{account.id} subscription canceled, downgraded to Free"
        notify_subscription_canceled(account)
      end

      def handle_subscription_paused(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        account.update!(subscription_status: "paused")
        Rails.logger.info "[Webhook] Account #{account.id} subscription paused"
      end

      def handle_subscription_resumed(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        account.update!(subscription_status: map_stripe_status(subscription.status))
        Rails.logger.info "[Webhook] Account #{account.id} subscription resumed"
      end

      def handle_trial_ending(subscription)
        account = find_account_from_subscription(subscription)
        return unless account

        Rails.logger.info "[Webhook] Account #{account.id} trial ending in 3 days"
        notify_trial_ending(account)
      end

      def handle_payment_failed(invoice)
        pay_customer = find_pay_customer(invoice.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner
        account.update!(subscription_status: "past_due")

        Rails.logger.warn "[Webhook] Account #{account.id} payment failed for invoice #{invoice.id}"
        notify_payment_issue(account)
      end

      def handle_payment_succeeded(invoice)
        pay_customer = find_pay_customer(invoice.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner

        # Only update if currently past_due (payment recovered)
        if account.subscription_status == "past_due"
          account.update!(subscription_status: "active")
          Rails.logger.info "[Webhook] Account #{account.id} payment recovered, status now active"
        end
      end

      # Finders

      def find_account_from_subscription(subscription)
        pay_customer = find_pay_customer(subscription.customer)
        return nil unless pay_customer&.owner.is_a?(Account)

        pay_customer.owner
      end

      def find_pay_customer(stripe_customer_id)
        Pay::Customer.find_by(processor: :stripe, processor_id: stripe_customer_id)
      end

      def find_plan_from_subscription(subscription)
        price_id = subscription.items&.data&.first&.price&.id
        return nil unless price_id

        Plan.find_by(stripe_price_id: price_id)
      end

      # Helpers

      def map_stripe_status(status)
        case status
        when "trialing" then "trialing"
        when "active" then "active"
        when "past_due" then "past_due"
        when "canceled", "unpaid" then "canceled"
        when "paused" then "paused"
        when "incomplete", "incomplete_expired" then "incomplete"
        else "active"
        end
      end

      def parse_timestamp(timestamp)
        return nil unless timestamp

        Time.at(timestamp)
      end

      # Notifications (implement these based on your notification system)

      def notify_trial_ending(account)
        # TODO: Implement trial ending notification
        # TrialEndingNotificationJob.perform_later(account.id)
      end

      def notify_payment_issue(account)
        # TODO: Implement payment issue notification
        # PaymentIssueNotificationJob.perform_later(account.id)
      end

      def notify_subscription_canceled(account)
        # TODO: Implement cancellation notification
        # SubscriptionCanceledNotificationJob.perform_later(account.id)
      end
    end
  end
end
