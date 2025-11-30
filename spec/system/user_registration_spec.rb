# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Registration", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "signing up" do
    it "allows a new user to register with valid information" do
      visit sign_up_path

      # Fill in the registration form
      fill_in "user[first_name]", with: "John"
      fill_in "user[last_name]", with: "Doe"
      fill_in "user[email]", with: "john.doe@example.com"
      fill_in "account[name]", with: "Acme Inc."
      fill_in "user[password]", with: "password123"
      fill_in "user[password_confirmation]", with: "password123"

      click_button "Create account"

      # Should redirect to dashboard after successful registration (auto-login)
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Welcome")
    end

    it "shows errors for invalid registration" do
      visit sign_up_path

      # Submit with empty email (required field)
      fill_in "user[first_name]", with: "John"
      fill_in "user[last_name]", with: "Doe"
      fill_in "user[email]", with: ""
      fill_in "account[name]", with: "Acme Inc."
      fill_in "user[password]", with: "password123"
      fill_in "user[password_confirmation]", with: "password123"

      click_button "Create account"

      # Should stay on sign up page and show validation
      expect(page).to have_current_path(sign_up_path)
    end

    it "shows error for password mismatch" do
      visit sign_up_path

      fill_in "user[first_name]", with: "John"
      fill_in "user[last_name]", with: "Doe"
      fill_in "user[email]", with: "john.doe@example.com"
      fill_in "account[name]", with: "Acme Inc."
      fill_in "user[password]", with: "password123"
      fill_in "user[password_confirmation]", with: "different123"

      click_button "Create account"

      expect(page).to have_content("Password confirmation doesn't match")
    end

    it "shows error for duplicate email" do
      create(:user, email: "existing@example.com")

      visit sign_up_path

      fill_in "user[first_name]", with: "John"
      fill_in "user[last_name]", with: "Doe"
      fill_in "user[email]", with: "existing@example.com"
      fill_in "account[name]", with: "Acme Inc."
      fill_in "user[password]", with: "password123"
      fill_in "user[password_confirmation]", with: "password123"

      click_button "Create account"

      expect(page).to have_content("already been taken")
    end
  end

  describe "page structure" do
    it "displays the sign up form with all fields" do
      visit sign_up_path

      expect(page).to have_content("Create your account")
      expect(page).to have_field("user[first_name]")
      expect(page).to have_field("user[last_name]")
      expect(page).to have_field("user[email]")
      expect(page).to have_field("account[name]")
      expect(page).to have_field("user[password]")
      expect(page).to have_field("user[password_confirmation]")
      expect(page).to have_button("Create account")
    end

    it "has a link to sign in for existing users" do
      visit sign_up_path

      expect(page).to have_link("Sign in", href: sign_in_path)
    end
  end
end
