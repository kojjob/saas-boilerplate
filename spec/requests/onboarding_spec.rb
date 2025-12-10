# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, :confirmed) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }

  before do
    sign_in(user)
  end

  describe "OnboardingProgress creation" do
    context "when user visits dashboard without onboarding progress" do
      it "creates an onboarding progress record" do
        expect { get dashboard_path }.to change(OnboardingProgress, :count).by(1)
      end
    end

    context "when user already has onboarding progress" do
      let!(:onboarding) { create(:onboarding_progress, user: user) }

      it "does not create another onboarding progress" do
        expect { get dashboard_path }.not_to change(OnboardingProgress, :count)
      end
    end
  end

  describe "GET /onboarding/dismiss" do
    let!(:onboarding) { create(:onboarding_progress, user: user) }

    it "dismisses the onboarding checklist" do
      delete dismiss_onboarding_path

      expect(onboarding.reload.dismissed_at).to be_present
    end

    it "redirects back to the previous page" do
      delete dismiss_onboarding_path

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "Onboarding step tracking" do
    let!(:onboarding) { create(:onboarding_progress, user: user) }

    context "when creating a client" do
      it "marks the created_client step as completed" do
        post clients_path, params: {
          client: {
            name: "Test Client",
            email: "test@example.com"
          }
        }

        expect(onboarding.reload.created_client_at).to be_present
      end
    end

    context "when creating a project" do
      let!(:client) { create(:client, account: account) }

      it "marks the created_project step as completed" do
        post projects_path, params: {
          project: {
            name: "Test Project",
            client_id: client.id,
            status: "active"
          }
        }

        expect(onboarding.reload.created_project_at).to be_present
      end
    end

    context "when creating an invoice" do
      let!(:client) { create(:client, account: account) }

      it "marks the created_invoice step as completed" do
        post invoices_path, params: {
          invoice: {
            client_id: client.id,
            issue_date: Date.today,
            due_date: Date.today + 30.days
          }
        }

        expect(onboarding.reload.created_invoice_at).to be_present
      end
    end
  end
end
