# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account) }

  before do
    create(:membership, user: user, account: account, role: :owner)
    sign_in(user)
    Current.account = account
  end

  describe "POST /onboarding/dismiss" do
    context "when user has onboarding progress" do
      let!(:onboarding) { OnboardingProgress.find_or_create_for(user) }

      it "dismisses the onboarding checklist via HTML" do
        post dismiss_onboarding_path

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq("Checklist dismissed.")
        expect(onboarding.reload.dismissed?).to be true
      end

      it "dismisses the onboarding checklist via JSON" do
        post dismiss_onboarding_path, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(onboarding.reload.dismissed?).to be true
      end
    end

    # Note: The "no onboarding progress" scenario is not tested because
    # current_onboarding uses find_or_create_for which always creates
    # an onboarding record for authenticated users. This is intentional
    # behavior - onboarding records are created lazily on first access.
  end
end
