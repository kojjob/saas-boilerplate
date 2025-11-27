# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TenantScoping', type: :controller do
  controller(ApplicationController) do
    include TenantScoping

    def index
      render plain: "Current tenant: #{current_account&.slug || 'none'}"
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  let(:account) { create(:account, slug: 'test-company') }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, account: account, role: 'owner') }

  describe 'tenant resolution' do
    context 'when no tenant is set' do
      it 'does not set a current account' do
        get :index
        expect(response.body).to include('Current tenant: none')
      end
    end

    context 'when tenant is set via subdomain' do
      before do
        account.update!(subdomain: 'testco')
      end

      it 'sets the current account from subdomain' do
        request.host = 'testco.example.com'
        get :index
        expect(response.body).to include('Current tenant: test-company')
      end
    end
  end
end
