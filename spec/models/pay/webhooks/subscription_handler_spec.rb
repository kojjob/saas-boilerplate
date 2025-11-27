# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Pay::Webhooks::SubscriptionHandler do
  subject(:handler) { described_class.new }

  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, :owner, user: user, account: account) }
  let!(:pro_plan) { create(:plan, :pro) }
  let!(:free_plan) { create(:plan, :free) }

  # Mock Stripe customer
  let(:stripe_customer_id) { "cus_test123" }

  # Create a Pay::Customer record
  let!(:pay_customer) do
    Pay::Customer.create!(
      owner: account,
      processor: :stripe,
      processor_id: stripe_customer_id
    )
  end

  describe "#call" do
    context "with customer.subscription.created event" do
      let(:subscription_data) do
        OpenStruct.new(
          customer: stripe_customer_id,
          status: "active",
          trial_end: nil,
          items: OpenStruct.new(
            data: [
              OpenStruct.new(
                price: OpenStruct.new(id: pro_plan.stripe_price_id)
              )
            ]
          )
        )
      end

      let(:event) do
        OpenStruct.new(
          type: "customer.subscription.created",
          data: OpenStruct.new(object: subscription_data)
        )
      end

      it "updates account with the new plan" do
        handler.call(event)
        account.reload

        expect(account.plan).to eq(pro_plan)
        expect(account.subscription_status).to eq("active")
      end
    end

    context "with customer.subscription.updated event" do
      let(:subscription_data) do
        OpenStruct.new(
          customer: stripe_customer_id,
          status: "trialing",
          trial_end: 1.week.from_now.to_i,
          items: OpenStruct.new(
            data: [
              OpenStruct.new(
                price: OpenStruct.new(id: pro_plan.stripe_price_id)
              )
            ]
          )
        )
      end

      let(:event) do
        OpenStruct.new(
          type: "customer.subscription.updated",
          data: OpenStruct.new(object: subscription_data)
        )
      end

      it "updates account subscription status" do
        handler.call(event)
        account.reload

        expect(account.plan).to eq(pro_plan)
        expect(account.subscription_status).to eq("trialing")
        expect(account.trial_ends_at).to be_present
      end
    end

    context "with customer.subscription.deleted event" do
      before do
        account.update!(plan: pro_plan, subscription_status: "active")
      end

      let(:subscription_data) do
        OpenStruct.new(
          customer: stripe_customer_id,
          status: "canceled"
        )
      end

      let(:event) do
        OpenStruct.new(
          type: "customer.subscription.deleted",
          data: OpenStruct.new(object: subscription_data)
        )
      end

      it "downgrades account to free plan" do
        handler.call(event)
        account.reload

        expect(account.plan).to eq(free_plan)
        expect(account.subscription_status).to eq("canceled")
      end
    end

    context "with customer.subscription.trial_will_end event" do
      let(:subscription_data) do
        OpenStruct.new(
          customer: stripe_customer_id,
          status: "trialing",
          trial_end: 3.days.from_now.to_i
        )
      end

      let(:event) do
        OpenStruct.new(
          type: "customer.subscription.trial_will_end",
          data: OpenStruct.new(object: subscription_data)
        )
      end

      it "handles trial ending notification" do
        # This currently just logs the event, can be expanded to send notifications
        expect { handler.call(event) }.not_to raise_error
      end
    end

    context "with unknown customer" do
      let(:subscription_data) do
        OpenStruct.new(
          customer: "cus_unknown",
          status: "active"
        )
      end

      let(:event) do
        OpenStruct.new(
          type: "customer.subscription.created",
          data: OpenStruct.new(object: subscription_data)
        )
      end

      it "does not raise an error" do
        expect { handler.call(event) }.not_to raise_error
      end

      it "does not update the account" do
        original_status = account.subscription_status
        handler.call(event)
        account.reload

        expect(account.subscription_status).to eq(original_status)
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

    it "defaults unknown status to active" do
      expect(handler.send(:map_stripe_status, "unknown")).to eq("active")
    end
  end
end
