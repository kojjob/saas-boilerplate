# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Billing', type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:membership) { create(:membership, :owner, user: user, account: account) }

  before do
    sign_in(user)
  end

  describe 'GET /billing' do
    let!(:free_plan) { create(:plan, :free) }
    let!(:starter_plan) { create(:plan, :starter) }
    let!(:pro_plan) { create(:plan, :pro) }
    let!(:enterprise_plan) { create(:plan, :enterprise) }

    it 'returns successful response' do
      get billing_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays available plans' do
      get billing_path
      expect(response.body).to include(free_plan.name)
      expect(response.body).to include(starter_plan.name)
      expect(response.body).to include(pro_plan.name)
    end

    context 'when account has a plan' do
      before do
        account.update!(plan: pro_plan, subscription_status: 'active')
      end

      it 'shows current plan information' do
        get billing_path
        expect(response.body).to include('Current Plan')
      end
    end
  end

  describe 'GET /billing/portal' do
    context 'when account has payment processor' do
      before do
        # Create a mock payment processor with flexible double
        payment_processor = double('PayCustomer',
          present?: true,
          billing_portal: double(url: 'https://billing.stripe.com/session/test_session')
        )
        allow_any_instance_of(Account).to receive(:payment_processor).and_return(payment_processor)
      end

      it 'redirects to Stripe billing portal' do
        get billing_portal_path
        expect(response).to redirect_to('https://billing.stripe.com/session/test_session')
      end
    end

    context 'when account has no payment processor' do
      before do
        allow_any_instance_of(Account).to receive(:payment_processor).and_return(nil)
      end

      it 'redirects to billing page with error' do
        get billing_portal_path
        expect(response).to redirect_to(billing_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST /billing/checkout' do
    let!(:pro_plan) { create(:plan, :pro) }

    context 'with valid paid plan' do
      before do
        # Create a mock payment processor with flexible double
        payment_processor = double('PayCustomer',
          checkout: double(url: 'https://checkout.stripe.com/session/test_checkout')
        )
        allow_any_instance_of(Account).to receive(:payment_processor).and_return(payment_processor)
      end

      it 'creates checkout session and redirects' do
        post billing_checkout_path, params: { plan_id: pro_plan.id }
        expect(response).to redirect_to('https://checkout.stripe.com/session/test_checkout')
      end
    end

    context 'with free plan' do
      let!(:free_plan) { create(:plan, :free) }

      it 'updates account directly without Stripe' do
        post billing_checkout_path, params: { plan_id: free_plan.id }
        expect(response).to redirect_to(billing_path)
        expect(flash[:notice]).to include('Successfully switched')
        account.reload
        expect(account.plan).to eq(free_plan)
      end
    end

    context 'with invalid plan' do
      it 'redirects to billing with error' do
        post billing_checkout_path, params: { plan_id: 0 }
        expect(response).to redirect_to(billing_path)
        expect(flash[:alert]).to include('Plan not found')
      end
    end
  end

  describe 'GET /billing/success' do
    it 'shows success message' do
      get billing_success_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('success').or include('Success')
    end
  end

  describe 'GET /billing/cancel' do
    it 'shows cancellation message' do
      get billing_cancel_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('cancel').or include('Cancel')
    end
  end
end
