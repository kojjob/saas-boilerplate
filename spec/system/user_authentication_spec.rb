# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Authentication", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:user) do
    create(:user, :confirmed,
           email: "test@example.com",
           password: "password123",
           password_confirmation: "password123")
  end
  let!(:account) { create(:account, name: "Test Company") }
  let!(:membership) { create(:membership, user: user, account: account, role: :owner) }

  describe "signing in" do
    it "allows a user to sign in with valid credentials" do
      visit sign_in_path

      fill_in "email", with: "test@example.com"
      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Dashboard")
    end

    it "shows error for invalid email" do
      visit sign_in_path

      fill_in "email", with: "wrong@example.com"
      fill_in "password", with: "password123"

      click_button "Sign in"

      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content("Invalid email or password")
    end

    it "shows error for invalid password" do
      visit sign_in_path

      fill_in "email", with: "test@example.com"
      fill_in "password", with: "wrongpassword"

      click_button "Sign in"

      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content("Invalid email or password")
    end

    it "allows sign in for unconfirmed email (email confirmation optional)" do
      # Note: The app allows unconfirmed users to sign in by design
      # This is a common pattern where email confirmation is encouraged but not required
      unconfirmed_user = create(:user,
                                 email: "unconfirmed@example.com",
                                 password: "password123",
                                 password_confirmation: "password123")
      create(:account).tap do |acc|
        create(:membership, user: unconfirmed_user, account: acc)
      end

      visit sign_in_path

      fill_in "email", with: "unconfirmed@example.com"
      fill_in "password", with: "password123"

      click_button "Sign in"

      # App allows sign in regardless of confirmation status
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe "signing out" do
    before do
      # Sign in first
      visit sign_in_path
      fill_in "email", with: "test@example.com"
      fill_in "password", with: "password123"
      click_button "Sign in"
      expect(page).to have_current_path(dashboard_path)
    end

    it "allows a user to sign out" do
      # Find and click sign out (usually in a dropdown or header)
      click_button "Sign out" if page.has_button?("Sign out")
      click_link "Sign out" if page.has_link?("Sign out")

      expect(page).to have_current_path(root_path).or have_current_path(sign_in_path)
    end
  end

  describe "remember me" do
    it "has a remember me checkbox" do
      visit sign_in_path

      expect(page).to have_field("remember_me")
    end
  end

  describe "page structure" do
    it "displays the sign in form with all elements" do
      visit sign_in_path

      expect(page).to have_content("Welcome back")
      expect(page).to have_field("email")
      expect(page).to have_field("password")
      expect(page).to have_button("Sign in")
      expect(page).to have_link("Forgot password?")
    end

    it "has a link to sign up for new users" do
      visit sign_in_path

      expect(page).to have_link("Sign up for free", href: sign_up_path)
    end
  end

  describe "protected routes" do
    it "redirects to sign in when accessing dashboard without authentication" do
      visit dashboard_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "redirects to sign in when accessing team members without authentication" do
      visit account_members_path

      expect(page).to have_current_path(sign_in_path)
    end
  end
end
