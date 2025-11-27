# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:owner) { create(:user, :confirmed) }
  let(:admin) { create(:user, :confirmed) }
  let(:member) { create(:user, :confirmed) }
  let(:guest) { create(:user, :confirmed) }
  let(:non_member) { create(:user, :confirmed) }

  let!(:owner_membership) { create(:membership, :owner, user: owner, account: account) }
  let!(:admin_membership) { create(:membership, user: admin, account: account, role: :admin) }
  let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }
  let!(:guest_membership) { create(:membership, user: guest, account: account, role: :guest) }

  before do
    ActsAsTenant.current_tenant = account
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'show?' do
    context 'as owner' do
      subject { described_class.new(owner, account) }
      it { is_expected.to permit_action(:show) }
    end

    context 'as admin' do
      subject { described_class.new(admin, account) }
      it { is_expected.to permit_action(:show) }
    end

    context 'as member' do
      subject { described_class.new(member, account) }
      it { is_expected.to permit_action(:show) }
    end

    context 'as guest' do
      subject { described_class.new(guest, account) }
      it { is_expected.to permit_action(:show) }
    end

    context 'as non-member' do
      subject { described_class.new(non_member, account) }
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe 'update?' do
    context 'as owner' do
      subject { described_class.new(owner, account) }
      it { is_expected.to permit_action(:update) }
    end

    context 'as admin' do
      subject { described_class.new(admin, account) }
      it { is_expected.to permit_action(:update) }
    end

    context 'as member' do
      subject { described_class.new(member, account) }
      it { is_expected.to forbid_action(:update) }
    end

    context 'as guest' do
      subject { described_class.new(guest, account) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'manage_billing?' do
    context 'as owner' do
      subject { described_class.new(owner, account) }
      it { is_expected.to permit_action(:manage_billing) }
    end

    context 'as admin' do
      subject { described_class.new(admin, account) }
      it { is_expected.to forbid_action(:manage_billing) }
    end

    context 'as member' do
      subject { described_class.new(member, account) }
      it { is_expected.to forbid_action(:manage_billing) }
    end

    context 'as guest' do
      subject { described_class.new(guest, account) }
      it { is_expected.to forbid_action(:manage_billing) }
    end
  end

  describe 'destroy?' do
    context 'as owner' do
      subject { described_class.new(owner, account) }
      it { is_expected.to permit_action(:destroy) }
    end

    context 'as admin' do
      subject { described_class.new(admin, account) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'as member' do
      subject { described_class.new(member, account) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'as guest' do
      subject { described_class.new(guest, account) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  describe 'transfer_ownership?' do
    context 'as owner' do
      subject { described_class.new(owner, account) }
      it { is_expected.to permit_action(:transfer_ownership) }
    end

    context 'as admin' do
      subject { described_class.new(admin, account) }
      it { is_expected.to forbid_action(:transfer_ownership) }
    end

    context 'as member' do
      subject { described_class.new(member, account) }
      it { is_expected.to forbid_action(:transfer_ownership) }
    end

    context 'as guest' do
      subject { described_class.new(guest, account) }
      it { is_expected.to forbid_action(:transfer_ownership) }
    end
  end

  describe 'Scope' do
    let(:other_account) { create(:account) }
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_membership) { create(:membership, :owner, user: other_user, account: other_account) }

    subject { described_class::Scope.new(owner, Account.all).resolve }

    it 'includes accounts the user is a member of' do
      expect(subject).to include(account)
    end

    it 'excludes accounts the user is not a member of' do
      expect(subject).not_to include(other_account)
    end
  end
end
