# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembershipPolicy, type: :policy do
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

  describe 'index?' do
    context 'as owner' do
      subject { described_class.new(owner, nil) }
      it { is_expected.to permit_action(:index) }
    end

    context 'as admin' do
      subject { described_class.new(admin, nil) }
      it { is_expected.to permit_action(:index) }
    end

    context 'as member' do
      subject { described_class.new(member, nil) }
      it { is_expected.to permit_action(:index) }
    end

    context 'as guest' do
      subject { described_class.new(guest, nil) }
      it { is_expected.to permit_action(:index) }
    end

    context 'as non-member' do
      subject { described_class.new(non_member, nil) }
      it { is_expected.to forbid_action(:index) }
    end
  end

  describe 'invite?' do
    context 'as owner' do
      subject { described_class.new(owner, nil) }
      it { is_expected.to permit_action(:invite) }
    end

    context 'as admin' do
      subject { described_class.new(admin, nil) }
      it { is_expected.to permit_action(:invite) }
    end

    context 'as member' do
      subject { described_class.new(member, nil) }
      it { is_expected.to forbid_action(:invite) }
    end

    context 'as guest' do
      subject { described_class.new(guest, nil) }
      it { is_expected.to forbid_action(:invite) }
    end
  end

  describe 'update?' do
    context 'as owner' do
      subject { described_class.new(owner, member_membership) }

      it { is_expected.to permit_action(:update) }

      context 'updating their own membership' do
        subject { described_class.new(owner, owner_membership) }
        it { is_expected.to forbid_action(:update) }
      end
    end

    context 'as admin' do
      context 'updating a member' do
        subject { described_class.new(admin, member_membership) }
        it { is_expected.to permit_action(:update) }
      end

      context 'updating a guest' do
        subject { described_class.new(admin, guest_membership) }
        it { is_expected.to permit_action(:update) }
      end

      context 'updating another admin' do
        let(:another_admin) { create(:user, :confirmed) }
        let!(:another_admin_membership) { create(:membership, user: another_admin, account: account, role: :admin) }

        subject { described_class.new(admin, another_admin_membership) }
        it { is_expected.to forbid_action(:update) }
      end

      context 'updating the owner' do
        subject { described_class.new(admin, owner_membership) }
        it { is_expected.to forbid_action(:update) }
      end

      context 'updating their own membership' do
        subject { described_class.new(admin, admin_membership) }
        it { is_expected.to forbid_action(:update) }
      end
    end

    context 'as member' do
      subject { described_class.new(member, guest_membership) }
      it { is_expected.to forbid_action(:update) }
    end

    context 'as guest' do
      subject { described_class.new(guest, member_membership) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'as owner' do
      context 'removing a member' do
        subject { described_class.new(owner, member_membership) }
        it { is_expected.to permit_action(:destroy) }
      end

      context 'removing themselves' do
        subject { described_class.new(owner, owner_membership) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context 'as admin' do
      context 'removing a member' do
        subject { described_class.new(admin, member_membership) }
        it { is_expected.to permit_action(:destroy) }
      end

      context 'removing a guest' do
        subject { described_class.new(admin, guest_membership) }
        it { is_expected.to permit_action(:destroy) }
      end

      context 'removing the owner' do
        subject { described_class.new(admin, owner_membership) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context 'removing another admin' do
        let(:another_admin) { create(:user, :confirmed) }
        let!(:another_admin_membership) { create(:membership, user: another_admin, account: account, role: :admin) }

        subject { described_class.new(admin, another_admin_membership) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context 'removing themselves' do
        subject { described_class.new(admin, admin_membership) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context 'as member' do
      context 'removing another member' do
        let(:another_member) { create(:user, :confirmed) }
        let!(:another_member_membership) { create(:membership, user: another_member, account: account, role: :member) }

        subject { described_class.new(member, another_member_membership) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context 'removing themselves (leaving account)' do
        subject { described_class.new(member, member_membership) }
        it { is_expected.to permit_action(:destroy) }
      end
    end

    context 'as guest' do
      context 'removing themselves (leaving account)' do
        subject { described_class.new(guest, guest_membership) }
        it { is_expected.to permit_action(:destroy) }
      end
    end
  end

  describe 'resend_invitation?' do
    let(:pending_invitation) do
      Membership.invite!(account: account, email: 'pending@example.com', role: 'member', invited_by: owner)
    end

    context 'as owner' do
      subject { described_class.new(owner, pending_invitation) }
      it { is_expected.to permit_action(:resend_invitation) }
    end

    context 'as admin' do
      subject { described_class.new(admin, pending_invitation) }
      it { is_expected.to permit_action(:resend_invitation) }
    end

    context 'as member' do
      subject { described_class.new(member, pending_invitation) }
      it { is_expected.to forbid_action(:resend_invitation) }
    end
  end

  describe 'cancel_invitation?' do
    let(:pending_invitation) do
      Membership.invite!(account: account, email: 'pending@example.com', role: 'member', invited_by: owner)
    end

    context 'as owner' do
      subject { described_class.new(owner, pending_invitation) }
      it { is_expected.to permit_action(:cancel_invitation) }
    end

    context 'as admin' do
      subject { described_class.new(admin, pending_invitation) }
      it { is_expected.to permit_action(:cancel_invitation) }
    end

    context 'as member' do
      subject { described_class.new(member, pending_invitation) }
      it { is_expected.to forbid_action(:cancel_invitation) }
    end
  end

  describe 'Scope' do
    let(:other_account) { create(:account) }
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_membership) { create(:membership, :owner, user: other_user, account: other_account) }

    subject { described_class::Scope.new(owner, Membership.all).resolve }

    it 'includes memberships from the current account' do
      expect(subject).to include(owner_membership, admin_membership, member_membership, guest_membership)
    end

    it 'excludes memberships from other accounts' do
      expect(subject).not_to include(other_membership)
    end
  end
end
