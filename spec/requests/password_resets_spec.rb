# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordResets', type: :request do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  # Modern browser User-Agent to pass allow_browser check
  let(:headers) do
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
  end

  describe 'GET /password_resets/new' do
    it 'renders the password reset request form' do
      get new_password_reset_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /password_resets' do
    context 'with valid email' do
      it 'generates a password reset token' do
        expect {
          post password_resets_path, params: { email: user.email }, headers: headers
        }.to change { user.reload.reset_password_token }.from(nil)
      end

      it 'sets the reset password sent at timestamp' do
        post password_resets_path, params: { email: user.email }, headers: headers
        expect(user.reload.reset_password_sent_at).to be_present
      end

      it 'redirects to sign in with success message' do
        post password_resets_path, params: { email: user.email }, headers: headers
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to include('instructions')
      end

      it 'enqueues a password reset email' do
        expect {
          post password_resets_path, params: { email: user.email }, headers: headers
        }.to have_enqueued_mail(PasswordResetMailer, :reset_email)
      end
    end

    context 'with non-existent email' do
      it 'still redirects to sign in (prevents email enumeration)' do
        post password_resets_path, params: { email: 'nonexistent@example.com' }, headers: headers
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to include('instructions')
      end

      it 'does not create any tokens' do
        expect {
          post password_resets_path, params: { email: 'nonexistent@example.com' }, headers: headers
        }.not_to change { User.where.not(reset_password_token: nil).count }
      end
    end

    context 'with blank email' do
      it 'renders the form with an error' do
        post password_resets_path, params: { email: '' }, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /password_resets/:token/edit' do
    before do
      user.generate_password_reset_token!
    end

    context 'with valid token' do
      it 'renders the password reset form' do
        get edit_password_reset_path(token: user.reset_password_token), headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid token' do
      it 'redirects to new password reset with error' do
        get edit_password_reset_path(token: 'invalid-token'), headers: headers
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include('invalid')
      end
    end

    context 'with expired token' do
      before do
        user.update!(reset_password_sent_at: 3.hours.ago)
      end

      it 'redirects to new password reset with expiration error' do
        get edit_password_reset_path(token: user.reset_password_token), headers: headers
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include('expired')
      end
    end
  end

  describe 'PATCH /password_resets/:token' do
    before do
      user.generate_password_reset_token!
    end

    context 'with valid token and matching passwords' do
      let(:new_password) { 'newpassword123' }

      it 'updates the user password' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: new_password, password_confirmation: new_password },
              headers: headers

        expect(user.reload.authenticate(new_password)).to be_truthy
      end

      it 'clears the password reset token' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: new_password, password_confirmation: new_password },
              headers: headers

        user.reload
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end

      it 'redirects to sign in with success message' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: new_password, password_confirmation: new_password },
              headers: headers

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to include('reset')
      end
    end

    context 'with invalid token' do
      it 'redirects to new password reset with error' do
        patch password_reset_path(token: 'invalid-token'),
              params: { password: 'newpassword123', password_confirmation: 'newpassword123' },
              headers: headers

        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include('invalid')
      end
    end

    context 'with expired token' do
      before do
        user.update!(reset_password_sent_at: 3.hours.ago)
      end

      it 'redirects to new password reset with expiration error' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: 'newpassword123', password_confirmation: 'newpassword123' },
              headers: headers

        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to include('expired')
      end
    end

    context 'with password mismatch' do
      it 'renders the edit form with an error' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: 'newpassword123', password_confirmation: 'different123' },
              headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not clear the password reset token' do
        original_token = user.reset_password_token

        patch password_reset_path(token: user.reset_password_token),
              params: { password: 'newpassword123', password_confirmation: 'different123' },
              headers: headers

        expect(user.reload.reset_password_token).to eq(original_token)
      end
    end

    context 'with password too short' do
      it 'renders the edit form with an error' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: 'short', password_confirmation: 'short' },
              headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with blank password' do
      it 'renders the edit form with an error' do
        patch password_reset_path(token: user.reset_password_token),
              params: { password: '', password_confirmation: '' },
              headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
