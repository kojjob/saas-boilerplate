# frozen_string_literal: true

class BillingController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :require_account!

  def index
    @plans = Plan.active.sorted
    @current_plan = current_account.current_plan
  end

  def portal
    if current_account.payment_processor.present?
      portal_session = current_account.payment_processor.billing_portal(
        return_url: billing_url
      )
      redirect_to portal_session.url, allow_other_host: true
    else
      redirect_to billing_path, alert: "No billing information available. Please subscribe to a plan first."
    end
  end

  def checkout
    plan = Plan.find_by(id: params[:plan_id])

    if plan.nil?
      redirect_to billing_path, alert: "Plan not found."
      return
    end

    if plan.free?
      # For free plan, just update the account directly
      current_account.update!(plan: plan, subscription_status: "active")
      redirect_to billing_path, notice: "Successfully switched to #{plan.name}."
      return
    end

    # Create Stripe checkout session
    checkout_session = current_account.payment_processor.checkout(
      mode: "subscription",
      line_items: [ { price: plan.stripe_price_id, quantity: 1 } ],
      success_url: billing_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: billing_cancel_url,
      subscription_data: {
        metadata: {
          plan_id: plan.id,
          account_id: current_account.id
        },
        trial_period_days: plan.trial_days.positive? ? plan.trial_days : nil
      }.compact
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def success
    @session_id = params[:session_id]
    flash.now[:notice] = "Your subscription was successful! Thank you for subscribing."
  end

  def cancel
    flash.now[:alert] = "Checkout was cancelled. You can try again anytime."
  end

  private

  def require_account!
    unless current_account
      redirect_to root_path, alert: "Please select an account first."
    end
  end
end
