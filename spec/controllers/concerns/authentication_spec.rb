# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :controller do
  controller(ApplicationController) do
    include Authentication
    skip_before_action :set_current_tenant_from_subdomain, raise: false

    def index
      render plain: "Hello, #{current_user&.full_name || 'Guest'}"
    end

    def protected_action
      authenticate_user!
      return if performed?

      render plain: 'Protected content'
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'protected_action' => 'anonymous#protected_action'
    end
  end

  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }
  let(:session_record) { create(:session, user: user) }

  describe '#current_user' do
    context 'when not signed in' do
      it 'returns nil' do
        get :index
        expect(controller.send(:current_user)).to be_nil
      end
    end

    context 'when signed in' do
      before do
        # Simulate a logged in session
        allow(controller).to receive(:current_session).and_return(session_record)
      end

      it 'returns the current user' do
        get :index
        expect(response.body).to include(user.full_name)
      end
    end
  end

  describe '#authenticate_user!' do
    context 'when not signed in' do
      it 'redirects to sign in page' do
        get :protected_action
        expect(response).to redirect_to('/sign_in')
      end
    end

    context 'when signed in' do
      before do
        allow(controller).to receive(:current_session).and_return(session_record)
      end

      it 'allows access to the action' do
        get :protected_action
        expect(response.body).to eq('Protected content')
      end
    end
  end

  describe '#sign_in' do
    it 'creates a session for the user' do
      expect {
        controller.send(:sign_in, user)
      }.to change(Session, :count).by(1)
    end
  end

  describe '#sign_out' do
    before do
      allow(controller).to receive(:current_session).and_return(session_record)
    end

    it 'destroys the current session' do
      expect {
        controller.send(:sign_out)
      }.to change(Session, :count).by(-1)
    end
  end
end
