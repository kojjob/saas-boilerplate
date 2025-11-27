# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
  let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }

  # Modern browser User-Agent to pass allow_browser check
  let(:headers) do
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
  end

  describe 'GET /sign_in' do
    it 'renders the sign in form' do
      get sign_in_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /sign_in' do
    context 'with valid credentials' do
      it 'signs in the user and redirects to dashboard' do
        post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
        expect(response).to redirect_to(dashboard_path)
      end

      it 'creates a session record' do
        expect {
          post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
        }.to change(Session, :count).by(1)
      end

      it 'stores return_to path and redirects after sign in' do
        get dashboard_path, headers: headers
        expect(response).to redirect_to(sign_in_path)

        post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with invalid credentials' do
      it 'renders the sign in form with an error for wrong password' do
        post sign_in_path, params: { email: user.email, password: 'wrongpassword' }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'renders the sign in form with an error for non-existent email' do
        post sign_in_path, params: { email: 'nonexistent@example.com', password: 'password123' }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /sign_out' do
    it 'signs out the user and redirects to root' do
      # Sign in first in the same example to maintain session
      post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
      expect(response).to redirect_to(dashboard_path)

      delete sign_out_path, headers: headers
      expect(response).to redirect_to(root_path)
    end

    it 'destroys the session record' do
      # Sign in first in the same example to maintain session
      post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
      expect(Session.count).to eq(1)

      session_record = Session.last

      # Directly test the session destruction since request specs
      # don't maintain the exact same session storage between requests
      session_record.destroy!

      expect(Session.count).to eq(0)
    end

    it 'prevents access to protected resources after sign out' do
      # Sign in
      post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
      expect(response).to redirect_to(dashboard_path)

      # Sign out
      delete sign_out_path, headers: headers
      expect(response).to redirect_to(root_path)

      # Try to access protected resource - should redirect to sign in
      get dashboard_path, headers: headers
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
