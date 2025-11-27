# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth Callbacks', type: :request do
  # Modern browser User-Agent to pass allow_browser check
  let(:headers) do
    { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
  end

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:github] = nil
  end

  describe 'Google OAuth' do
    let(:google_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'user@gmail.com',
          first_name: 'John',
          last_name: 'Doe',
          image: 'https://lh3.googleusercontent.com/photo.jpg'
        },
        credentials: {
          token: 'mock_token',
          refresh_token: 'mock_refresh_token',
          expires_at: 1.week.from_now.to_i
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          get '/auth/google_oauth2/callback', headers: headers
        }.to change(User, :count).by(1)
      end

      it 'creates a new account' do
        expect {
          get '/auth/google_oauth2/callback', headers: headers
        }.to change(Account, :count).by(1)
      end

      it 'creates a membership as owner' do
        get '/auth/google_oauth2/callback', headers: headers

        user = User.last
        account = Account.last
        membership = Membership.find_by(user: user, account: account)

        expect(membership).to be_present
        expect(membership.role).to eq('owner')
      end

      it 'signs in the user' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(Session.count).to eq(1)
      end

      it 'redirects to the dashboard' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets a welcome flash message' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(flash[:notice]).to include('Successfully')
      end

      it 'stores OAuth credentials on the user' do
        get '/auth/google_oauth2/callback', headers: headers

        user = User.last
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
      end

      it 'marks the user as confirmed' do
        get '/auth/google_oauth2/callback', headers: headers

        user = User.last
        expect(user.confirmed?).to be true
      end
    end

    context 'when user already exists with same OAuth provider' do
      let!(:account) { create(:account) }
      let!(:existing_user) do
        create(:user,
          email: 'user@gmail.com',
          provider: 'google_oauth2',
          uid: '123456789',
          confirmed_at: Time.current
        )
      end
      let!(:membership) { create(:membership, user: existing_user, account: account, role: 'owner') }

      it 'does not create a new user' do
        expect {
          get '/auth/google_oauth2/callback', headers: headers
        }.not_to change(User, :count)
      end

      it 'signs in the existing user' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(Session.last.user).to eq(existing_user)
      end

      it 'redirects to the dashboard' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user exists with same email but different provider' do
      let!(:account) { create(:account) }
      let!(:existing_user) do
        create(:user,
          email: 'user@gmail.com',
          provider: nil,
          uid: nil,
          confirmed_at: Time.current
        )
      end
      let!(:membership) { create(:membership, user: existing_user, account: account, role: 'owner') }

      it 'links the OAuth account to the existing user' do
        get '/auth/google_oauth2/callback', headers: headers

        existing_user.reload
        expect(existing_user.provider).to eq('google_oauth2')
        expect(existing_user.uid).to eq('123456789')
      end

      it 'does not create a new user' do
        expect {
          get '/auth/google_oauth2/callback', headers: headers
        }.not_to change(User, :count)
      end

      it 'signs in the existing user' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(Session.last.user).to eq(existing_user)
      end
    end

    context 'when OAuth authentication fails' do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
      end

      it 'redirects to sign in page' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(response).to redirect_to(sign_in_path)
      end

      it 'displays an error message' do
        get '/auth/google_oauth2/callback', headers: headers
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GitHub OAuth' do
    let(:github_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '987654321',
        info: {
          email: 'developer@github.com',
          name: 'Jane Developer',
          nickname: 'janedev',
          image: 'https://avatars.githubusercontent.com/u/987654321'
        },
        credentials: {
          token: 'mock_github_token',
          expires: false
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:github] = github_auth_hash
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect {
          get '/auth/github/callback', headers: headers
        }.to change(User, :count).by(1)
      end

      it 'parses name into first and last name' do
        get '/auth/github/callback', headers: headers

        user = User.last
        expect(user.first_name).to eq('Jane')
        expect(user.last_name).to eq('Developer')
      end

      it 'stores OAuth credentials on the user' do
        get '/auth/github/callback', headers: headers

        user = User.last
        expect(user.provider).to eq('github')
        expect(user.uid).to eq('987654321')
      end

      it 'redirects to the dashboard' do
        get '/auth/github/callback', headers: headers
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when GitHub returns no email' do
      before do
        OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
          provider: 'github',
          uid: '111222333',
          info: {
            email: nil,
            name: 'No Email User',
            nickname: 'noemail'
          },
          credentials: {
            token: 'mock_token'
          }
        })
      end

      it 'redirects to sign in page' do
        get '/auth/github/callback', headers: headers
        expect(response).to redirect_to(sign_in_path)
      end

      it 'displays an error message about email requirement' do
        get '/auth/github/callback', headers: headers
        expect(flash[:alert]).to include('email')
      end
    end
  end

  describe 'User already signed in' do
    let!(:account) { create(:account) }
    let!(:user) { create(:user, confirmed_at: Time.current) }
    let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }

    before do
      post sign_in_path, params: { email: user.email, password: 'password123' }, headers: headers
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '999888777',
        info: {
          email: 'different@gmail.com',
          first_name: 'Different',
          last_name: 'User'
        },
        credentials: { token: 'mock_token' }
      })
    end

    it 'redirects to dashboard' do
      get '/auth/google_oauth2/callback', headers: headers
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
