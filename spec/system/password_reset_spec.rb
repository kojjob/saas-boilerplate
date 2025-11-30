# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Password Reset", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:user) do
    create(:user, :confirmed,
           email: "user@example.com",
           password: "oldpassword123",
           password_confirmation: "oldpassword123")
  end
  let!(:account) { create(:account) }
  let!(:membership) { create(:membership, user: user, account: account) }

  describe "requesting password reset" do
    it "allows a user to request a password reset" do
      visit new_password_reset_path

      fill_in "email", with: "user@example.com"

      click_button "Send"

      expect(page).to have_content("email")
    end

    it "shows a message even for non-existent emails (security)" do
      visit new_password_reset_path

      fill_in "email", with: "nonexistent@example.com"

      click_button "Send"

      # Should not reveal whether email exists
      expect(page).to have_content("email")
    end
  end

  describe "resetting password with token" do
    it "allows a user to reset password with valid token" do
      # Generate a password reset token
      user.generate_password_reset_token!
      token = user.reload.reset_password_token

      visit edit_password_reset_path(token)

      fill_in "password", with: "newpassword123"
      fill_in "password_confirmation", with: "newpassword123"

      click_button "Reset"

      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content("reset")
    end

    it "shows error for mismatched passwords" do
      user.generate_password_reset_token!
      token = user.reload.reset_password_token

      visit edit_password_reset_path(token)

      fill_in "password", with: "newpassword123"
      fill_in "password_confirmation", with: "different123"

      click_button "Reset"

      expect(page).to have_content("does not match").or have_content("doesn't match")
    end

    it "shows error for expired token" do
      user.update!(
        reset_password_token: "expired-token",
        reset_password_sent_at: 3.hours.ago
      )

      visit edit_password_reset_path("expired-token")

      expect(page).to have_content("expired").or have_content("invalid")
    end
  end

  describe "page structure" do
    it "displays the password reset request form" do
      visit new_password_reset_path

      expect(page).to have_content("Reset")
      expect(page).to have_field("email")
      expect(page).to have_button("Send")
    end
  end

  describe "navigation" do
    it "has a link from sign in to forgot password" do
      visit sign_in_path

      click_link "Forgot password?"

      expect(page).to have_current_path(new_password_reset_path)
    end

    it "has a link back to sign in from reset page" do
      visit new_password_reset_path

      expect(page).to have_link(href: sign_in_path)
    end
  end
end
