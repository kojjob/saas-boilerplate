# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Pay::Webhooks::SubscriptionHandler do
  subject(:handler) { described_class.new }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let!(:free_plan) { create(:plan, :free) }
  let!(:pro_plan) { create(:plan, :pro) }
  let(:stripe_customer_id) { "cus_test123" }

  before do
    # Create a Pay::Customer for the account
    Pay::Customer.create!(
      owner: account,
      processor: :stripe,
      processor_id: stripe_customer_id
    )
  end

  describe "#call" do
    context "when processing customer.subscription.created" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.created",
          build_subscription(status: "active", price_id: pro_plan.stripe_price_id)
        )
      end

      it "updates the account plan" do
        expect { handler.call(event) }.to change { account.reload.plan }.to(pro_plan)
      end

      it "sets the subscription status to active" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("active")
      end
    end

    context "when processing customer.subscription.updated" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.updated",
          build_subscription(status: "active", price_id: pro_plan.stripe_price_id)
        )
      end

      before { account.update!(plan: free_plan, subscription_status: "trialing") }

      it "updates the account plan" do
        expect { handler.call(event) }.to change { account.reload.plan }.to(pro_plan)
      end

      it "updates the subscription status" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("active")
      end
    end

    context "when processing customer.subscription.deleted" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.deleted",
          build_subscription(status: "canceled", price_id: pro_plan.stripe_price_id)
        )
      end

      before { account.update!(plan: pro_plan, subscription_status: "active") }

      it "downgrades the account to free plan" do
        expect { handler.call(event) }.to change { account.reload.plan }.to(free_plan)
      end

      it "sets the subscription status to canceled" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("canceled")
      end

      it "clears the trial_ends_at" do
        account.update!(trial_ends_at: 3.days.from_now)
        handler.call(event)
        expect(account.reload.trial_ends_at).to be_nil
      end
    end

    context "when processing customer.subscription.trial_will_end" do
      let(:trial_end) { 3.days.from_now.to_i }
      let(:event) do
        build_stripe_event(
          "customer.subscription.trial_will_end",
          build_subscription(status: "trialing", trial_end: trial_end, price_id: pro_plan.stripe_price_id)
        )
      end

      before { account.update!(plan: pro_plan, subscription_status: "trialing") }

      it "logs the trial ending notification" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/trial ending in 3 days/)
        handler.call(event)
      end
    end

    context "when processing customer.subscription.paused" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.paused",
          build_subscription(status: "paused", price_id: pro_plan.stripe_price_id)
        )
      end

      before { account.update!(plan: pro_plan, subscription_status: "active") }

      it "sets the subscription status to paused" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("paused")
      end
    end

    context "when processing customer.subscription.resumed" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.resumed",
          build_subscription(status: "active", price_id: pro_plan.stripe_price_id)
        )
      end

      before { account.update!(plan: pro_plan, subscription_status: "paused") }

      it "sets the subscription status to active" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("active")
      end
    end

    context "when processing invoice.payment_failed" do
      let(:event) do
        build_stripe_event(
          "invoice.payment_failed",
          build_invoice(customer: stripe_customer_id)
        )
      end

      before { account.update!(plan: pro_plan, subscription_status: "active") }

      it "sets the subscription status to past_due" do
        handler.call(event)
        expect(account.reload.subscription_status).to eq("past_due")
      end
    end

    context "when processing invoice.payment_succeeded" do
      let(:event) do
        build_stripe_event(
          "invoice.payment_succeeded",
          build_invoice(customer: stripe_customer_id)
        )
      end

      context "when account was past_due" do
        before { account.update!(plan: pro_plan, subscription_status: "past_due") }

        it "sets the subscription status to active" do
          handler.call(event)
          expect(account.reload.subscription_status).to eq("active")
        end
      end

      context "when account was already active" do
        before { account.update!(plan: pro_plan, subscription_status: "active") }

        it "keeps the subscription status as active" do
          handler.call(event)
          expect(account.reload.subscription_status).to eq("active")
        end
      end
    end

    context "when Pay::Customer is not found" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.created",
          build_subscription(customer: "cus_unknown", status: "active", price_id: pro_plan.stripe_price_id)
        )
      end

      it "does not raise an error" do
        expect { handler.call(event) }.not_to raise_error
      end

      it "does not update any account" do
        expect { handler.call(event) }.not_to change { Account.pluck(:subscription_status) }
      end
    end

    context "when Plan is not found by stripe_price_id" do
      let(:event) do
        build_stripe_event(
          "customer.subscription.created",
          build_subscription(status: "active", price_id: "price_unknown")
        )
      end

      it "sets the plan to nil" do
        handler.call(event)
        expect(account.reload.plan).to be_nil
      end
    end
  end

  describe "#map_stripe_status" do
    it "maps trialing to trialing" do
      expect(handler.send(:map_stripe_status, "trialing")).to eq("trialing")
    end

    it "maps active to active" do
      expect(handler.send(:map_stripe_status, "active")).to eq("active")
    end

    it "maps past_due to past_due" do
      expect(handler.send(:map_stripe_status, "past_due")).to eq("past_due")
    end

    it "maps canceled to canceled" do
      expect(handler.send(:map_stripe_status, "canceled")).to eq("canceled")
    end

    it "maps unpaid to canceled" do
      expect(handler.send(:map_stripe_status, "unpaid")).to eq("canceled")
    end

    it "maps paused to paused" do
      expect(handler.send(:map_stripe_status, "paused")).to eq("paused")
    end

    it "maps incomplete to incomplete" do
      expect(handler.send(:map_stripe_status, "incomplete")).to eq("incomplete")
    end

    it "maps unknown status to active" do
      expect(handler.send(:map_stripe_status, "some_unknown_status")).to eq("active")
    end
  end

  # Helper methods to build mock Stripe objects

  def build_stripe_event(type, object)
    OpenStruct.new(
      type: type,
      data: OpenStruct.new(object: object)
    )
  end

  def build_subscription(customer: stripe_customer_id, status:, price_id:, trial_end: nil)
    OpenStruct.new(
      id: "sub_test123",
      customer: customer,
      status: status,
      trial_end: trial_end,
      items: OpenStruct.new(
        data: [
          OpenStruct.new(
            price: OpenStruct.new(id: price_id)
          )
        ]
      )
    )
  end

  def build_invoice(customer:)
    OpenStruct.new(
      id: "in_test123",
      customer: customer
    )
  end
end
