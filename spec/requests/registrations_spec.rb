# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registrations', type: :request do
  # Modern browser User-Agent to pass allow_browser check
  let(:headers) do
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
  end

  let(:valid_params) do
    {
      user: {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe'
      },
      account: {
        name: 'Test Company'
      }
    }
  end

  describe 'GET /sign_up' do
    it 'renders the registration form' do
      get sign_up_path, headers: headers
      expect(response).to have_http_status(:ok)
    end

    context 'when user is already signed in' do
      let(:account) { create(:account) }
      let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
      let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }

      it 'redirects to dashboard' do
        # Sign in the user first
        post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
        expect(response).to redirect_to(dashboard_path)

        # Now try to access sign up - should redirect to dashboard
        get sign_up_path, headers: headers
        expect(response).to redirect_to(dashboard_path)
      end

      it 'prevents registration when signed in' do
        # Sign in the user first
        post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
        expect(response).to redirect_to(dashboard_path)

        # Try to register - should redirect, not create user
        expect {
          post sign_up_path, params: valid_params, headers: headers
        }.not_to change(User, :count)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'POST /sign_up' do
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post sign_up_path, params: valid_params, headers: headers
        }.to change(User, :count).by(1)
      end

      it 'creates a new account' do
        expect {
          post sign_up_path, params: valid_params, headers: headers
        }.to change(Account, :count).by(1)
      end

      it 'creates a membership as owner' do
        post sign_up_path, params: valid_params, headers: headers

        user = User.last
        account = Account.last
        membership = Membership.find_by(user: user, account: account)

        expect(membership).to be_present
        expect(membership.role).to eq('owner')
      end

      it 'signs in the user' do
        post sign_up_path, params: valid_params, headers: headers
        expect(Session.count).to eq(1)
      end

      it 'redirects to the dashboard' do
        post sign_up_path, params: valid_params, headers: headers
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a welcome flash message' do
        post sign_up_path, params: valid_params, headers: headers
        expect(flash[:notice]).to include('Welcome')
      end
    end

    context 'with invalid user parameters' do
      it 'does not create a user with blank email' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ''

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(User, :count)
      end

      it 'does not create a user with invalid email format' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = 'not-an-email'

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(User, :count)
      end

      it 'does not create a user with short password' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password] = 'short'
        invalid_params[:user][:password_confirmation] = 'short'

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(User, :count)
      end

      it 'does not create a user when password confirmation does not match' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password_confirmation] = 'different123'

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(User, :count)
      end

      it 'renders the registration form with errors' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ''

        post sign_up_path, params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid account parameters' do
      it 'does not create an account with blank name' do
        invalid_params = valid_params.deep_dup
        invalid_params[:account][:name] = ''

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(Account, :count)
      end

      it 'does not create user if account is invalid' do
        invalid_params = valid_params.deep_dup
        invalid_params[:account][:name] = ''

        expect {
          post sign_up_path, params: invalid_params, headers: headers
        }.not_to change(User, :count)
      end
    end

    context 'with duplicate email' do
      before do
        create(:user, email: 'newuser@example.com')
      end

      it 'does not create a new user' do
        expect {
          post sign_up_path, params: valid_params, headers: headers
        }.not_to change(User, :count)
      end

      it 'renders the registration form with errors' do
        post sign_up_path, params: valid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user is already signed in' do
      let(:account) { create(:account) }
      let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
      let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }

      it 'redirects to dashboard' do
        post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers

        post sign_up_path, params: valid_params, headers: headers
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
