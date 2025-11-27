# frozen_string_literal: true

module Pay
  module Webhooks
    class SubscriptionHandler
      def call(event)
        subscription = event.data.object
        return unless subscription

        case event.type
        when "customer.subscription.created"
          handle_subscription_created(subscription)
        when "customer.subscription.updated"
          handle_subscription_updated(subscription)
        when "customer.subscription.deleted"
          handle_subscription_deleted(subscription)
        when "customer.subscription.trial_will_end"
          handle_trial_ending(subscription)
        end
      end

      private

      def handle_subscription_created(subscription)
        pay_customer = find_pay_customer(subscription.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner
        plan = find_plan_from_subscription(subscription)

        account.update!(
          plan: plan,
          subscription_status: map_stripe_status(subscription.status),
          trial_ends_at: subscription.trial_end ? Time.at(subscription.trial_end) : nil
        )
      end

      def handle_subscription_updated(subscription)
        pay_customer = find_pay_customer(subscription.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner
        plan = find_plan_from_subscription(subscription)

        account.update!(
          plan: plan,
          subscription_status: map_stripe_status(subscription.status),
          trial_ends_at: subscription.trial_end ? Time.at(subscription.trial_end) : nil
        )
      end

      def handle_subscription_deleted(subscription)
        pay_customer = find_pay_customer(subscription.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner

        # Downgrade to free plan on cancellation
        free_plan = Plan.free.first

        account.update!(
          plan: free_plan,
          subscription_status: "canceled"
        )
      end

      def handle_trial_ending(subscription)
        pay_customer = find_pay_customer(subscription.customer)
        return unless pay_customer&.owner.is_a?(Account)

        account = pay_customer.owner

        # Send trial ending notification (optional: implement as a job)
        # TrialEndingNotificationJob.perform_later(account.id)
      end

      def find_pay_customer(stripe_customer_id)
        Pay::Customer.find_by(processor: :stripe, processor_id: stripe_customer_id)
      end

      def find_plan_from_subscription(subscription)
        # Get the price ID from the subscription
        price_id = subscription.items&.data&.first&.price&.id
        return nil unless price_id

        Plan.find_by(stripe_price_id: price_id)
      end

      def map_stripe_status(status)
        case status
        when "trialing" then "trialing"
        when "active" then "active"
        when "past_due" then "past_due"
        when "canceled", "unpaid" then "canceled"
        when "paused" then "paused"
        else "active"
        end
      end
    end
  end
end
