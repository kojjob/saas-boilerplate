# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TenantScoped, type: :model do
  # Create a temporary model for testing
  with_model :TenantScopedResource do
    table do |t|
      t.references :account, null: false
      t.string :name
      t.timestamps
    end

    model do
      include TenantScoped
    end
  end

  let(:account1) { create(:account) }
  let(:account2) { create(:account) }

  describe 'tenant scoping' do
    before do
      ActsAsTenant.current_tenant = nil
    end

    context 'without a current tenant' do
      it 'includes all records' do
        TenantScopedResource.create!(name: 'Resource 1', account: account1)
        TenantScopedResource.create!(name: 'Resource 2', account: account2)

        expect(TenantScopedResource.count).to eq(2)
      end
    end

    context 'with a current tenant' do
      before do
        TenantScopedResource.create!(name: 'Resource 1', account: account1)
        TenantScopedResource.create!(name: 'Resource 2', account: account2)
      end

      it 'scopes queries to the current tenant' do
        ActsAsTenant.current_tenant = account1

        expect(TenantScopedResource.count).to eq(1)
        expect(TenantScopedResource.first.name).to eq('Resource 1')
      end

      it 'prevents access to other tenant records' do
        ActsAsTenant.current_tenant = account1

        expect(TenantScopedResource.find_by(name: 'Resource 2')).to be_nil
      end
    end

    context 'when creating records' do
      it 'automatically assigns the current tenant' do
        ActsAsTenant.current_tenant = account1

        resource = TenantScopedResource.create!(name: 'New Resource')

        expect(resource.account).to eq(account1)
      end

      it 'raises error when creating without a tenant and account_id missing' do
        ActsAsTenant.current_tenant = nil

        resource = TenantScopedResource.new(name: 'Invalid Resource')
        expect(resource).not_to be_valid
        expect(resource.errors[:account_id]).to include("can't be blank")
      end
    end
  end
end
