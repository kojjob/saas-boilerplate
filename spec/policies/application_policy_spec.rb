# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let(:record) { create(:account) }

  subject { described_class.new(user, record) }

  describe 'default permissions' do
    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe 'Scope' do
    let(:scope) { Account.all }

    it 'returns empty scope by default' do
      policy_scope = ApplicationPolicy::Scope.new(user, scope).resolve
      expect(policy_scope).to eq(scope.none)
    end
  end
end
