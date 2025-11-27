# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Confirmations', type: :request do
  describe 'GET /confirm_email/:token' do
    context 'with valid token' do
      let!(:user) { create(:user, confirmed_at: nil) }

      it 'confirms the user email' do
        expect {
          get confirm_email_path(token: user.confirmation_token)
        }.to change { user.reload.confirmed_at }.from(nil)
      end

      it 'clears the confirmation token' do
        get confirm_email_path(token: user.confirmation_token)
        expect(user.reload.confirmation_token).to be_nil
      end

      it 'redirects to sign in page with success message' do
        get confirm_email_path(token: user.confirmation_token)
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include('email has been confirmed')
      end

      it 'sets confirmed_at to current time' do
        travel_to Time.current do
          get confirm_email_path(token: user.confirmation_token)
          expect(user.reload.confirmed_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'with already confirmed user' do
      let!(:user) { create(:user, confirmed_at: 1.day.ago, confirmation_token: 'old-token') }

      it 'redirects to sign in page' do
        get confirm_email_path(token: 'old-token')
        expect(response).to redirect_to(sign_in_path)
      end

      it 'shows already confirmed message' do
        get confirm_email_path(token: 'old-token')
        follow_redirect!
        expect(response.body).to include('already been confirmed')
      end
    end

    context 'with invalid token' do
      it 'redirects to sign in page' do
        get confirm_email_path(token: 'invalid-token')
        expect(response).to redirect_to(sign_in_path)
      end

      it 'shows error message' do
        get confirm_email_path(token: 'invalid-token')
        follow_redirect!
        expect(response.body).to include('invalid')
      end
    end

    context 'with blank or whitespace token' do
      it 'redirects to sign in page with error for whitespace token' do
        get confirm_email_path(token: '   ')
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include('invalid')
      end
    end

    context 'when user is already signed in' do
      let!(:account) { create(:account) }
      let!(:signed_in_user) { create(:user, confirmed_at: Time.current) }
      let!(:membership) { create(:membership, user: signed_in_user, account: account, role: :owner) }
      let!(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      before do
        # Sign in the user
        post sign_in_path, params: { email: signed_in_user.email, password: 'password123' }
      end

      it 'still confirms the email when clicking confirmation link' do
        expect {
          get confirm_email_path(token: unconfirmed_user.confirmation_token)
        }.to change { unconfirmed_user.reload.confirmed_at }.from(nil)
      end

      it 'redirects to dashboard' do
        get confirm_email_path(token: unconfirmed_user.confirmation_token)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'POST /confirmations (resend confirmation)' do
    let!(:user) { create(:user, confirmed_at: nil) }

    context 'with valid email' do
      it 'regenerates confirmation token' do
        old_token = user.confirmation_token
        post confirmations_path, params: { email: user.email }
        expect(user.reload.confirmation_token).not_to eq(old_token)
      end

      it 'sends confirmation email' do
        expect {
          post confirmations_path, params: { email: user.email }
        }.to have_enqueued_mail(ConfirmationMailer, :confirmation_email)
      end

      it 'redirects to sign in with notice' do
        post confirmations_path, params: { email: user.email }
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include('confirmation instructions')
      end
    end

    context 'with already confirmed email' do
      let!(:confirmed_user) { create(:user, confirmed_at: Time.current) }

      it 'does not send email' do
        expect {
          post confirmations_path, params: { email: confirmed_user.email }
        }.not_to have_enqueued_mail(ConfirmationMailer, :confirmation_email)
      end

      it 'still shows success message to prevent email enumeration' do
        post confirmations_path, params: { email: confirmed_user.email }
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include('confirmation instructions')
      end
    end

    context 'with non-existent email' do
      it 'does not raise error' do
        expect {
          post confirmations_path, params: { email: 'nonexistent@example.com' }
        }.not_to raise_error
      end

      it 'still shows success message to prevent email enumeration' do
        post confirmations_path, params: { email: 'nonexistent@example.com' }
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include('confirmation instructions')
      end
    end

    context 'with blank email' do
      it 'renders new form with error' do
        post confirmations_path, params: { email: '' }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'shows error message' do
        post confirmations_path, params: { email: '' }
        expect(response.body).to include('enter your email')
      end
    end
  end

  describe 'GET /confirmations/new (resend form)' do
    it 'renders the resend confirmation form' do
      get new_confirmation_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays the resend confirmation form' do
      get new_confirmation_path
      expect(response.body).to include('Resend confirmation')
    end

    context 'when user is already signed in' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, confirmed_at: Time.current) }
      let!(:membership) { create(:membership, user: user, account: account, role: :owner) }

      before do
        post sign_in_path, params: { email: user.email, password: 'password123' }
      end

      it 'redirects to dashboard' do
        get new_confirmation_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
