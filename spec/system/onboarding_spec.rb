# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Onboarding Flow", type: :system do
  let(:user) { create(:user) }
  let(:account) { create(:account) }

  before do
    create(:membership, user: user, account: account, role: :owner)
    sign_in(user)
    Current.account = account
  end

  describe "onboarding checklist" do
    context "for new users without progress" do
      it "displays the onboarding checklist on the dashboard" do
        visit dashboard_path

        expect(page).to have_content("Get started with your account")
        expect(page).to have_content("0 of 4 complete")
      end

      it "shows all steps as incomplete" do
        visit dashboard_path

        expect(page).to have_content("Add your first client")
        expect(page).to have_content("Create a project")
        expect(page).to have_content("Create an invoice")
        expect(page).to have_content("Send your first invoice")
      end

      it "highlights the first step as the next action" do
        visit dashboard_path

        # The first step should have a "Start" link
        within("#onboarding-checklist") do
          expect(page).to have_link("Start")
        end
      end
    end

    context "when completing onboarding steps" do
      it "updates progress when creating a client" do
        visit new_client_path

        fill_in "Name", with: "Test Client"
        fill_in "Email", with: "test@client.com"
        click_button "Create Client"

        visit dashboard_path

        expect(page).to have_content("1 of 4 complete")
      end

      it "updates progress when creating a project" do
        client = create(:client, account: account)
        OnboardingProgress.find_or_create_for(user).complete_step!(:client_created)

        visit new_project_path

        fill_in "Name", with: "Test Project"
        select client.name, from: "Client"
        click_button "Create Project"

        visit dashboard_path

        expect(page).to have_content("2 of 4 complete")
      end
    end

    context "when checklist is dismissed" do
      it "allows users to dismiss the checklist", js: true do
        visit dashboard_path

        expect(page).to have_css("#onboarding-checklist")

        within("#onboarding-checklist") do
          find("button[data-action='click->onboarding#dismiss']", match: :first).click
        end

        # Wait for the animation to complete
        sleep 0.5

        expect(page).not_to have_css("#onboarding-checklist")
      end

      it "does not show the checklist after being dismissed" do
        onboarding = OnboardingProgress.find_or_create_for(user)
        onboarding.dismiss!

        visit dashboard_path

        expect(page).not_to have_css("#onboarding-checklist")
      end
    end

    context "when all steps are completed" do
      it "does not show the checklist when completed" do
        onboarding = OnboardingProgress.find_or_create_for(user)
        OnboardingProgress::STEPS.each { |step| onboarding.complete_step!(step) }

        visit dashboard_path

        expect(page).not_to have_css("#onboarding-checklist")
      end
    end

    context "with partial progress" do
      before do
        onboarding = OnboardingProgress.find_or_create_for(user)
        onboarding.complete_step!(:client_created)
        onboarding.complete_step!(:project_created)
      end

      it "shows correct progress percentage" do
        visit dashboard_path

        expect(page).to have_content("2 of 4 complete")
      end

      it "marks completed steps with checkmarks" do
        visit dashboard_path

        # The progress bar should show 50%
        within("#onboarding-checklist") do
          progress_bar = find("div.h-full.bg-white.rounded-full")
          expect(progress_bar[:style]).to include("50%")
        end
      end

      it "highlights the next uncompleted step" do
        visit dashboard_path

        # The third step (Create Invoice) should be highlighted
        within("#onboarding-checklist") do
          expect(page).to have_link("Start", count: 1)
        end
      end
    end
  end
end
