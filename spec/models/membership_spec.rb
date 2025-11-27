# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    subject { build(:membership) }

    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:account_id).with_message('is already a member of this account') }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:account) }
    it { should belong_to(:invited_by).class_name('User').optional }
  end

  describe 'roles' do
    it 'defines valid roles' do
      expect(Membership.roles.keys).to match_array(%w[owner admin member guest])
    end

    it 'defaults to member role' do
      membership = Membership.new
      expect(membership.role).to eq('member')
    end
  end

  describe 'role hierarchy' do
    describe '#owner?' do
      it 'returns true for owner role' do
        membership = build(:membership, role: :owner)
        expect(membership.owner?).to be true
      end
    end

    describe '#admin?' do
      it 'returns true for admin role' do
        membership = build(:membership, role: :admin)
        expect(membership.admin?).to be true
      end
    end

    describe '#admin_or_owner?' do
      it 'returns true for owner' do
        membership = build(:membership, role: :owner)
        expect(membership.admin_or_owner?).to be true
      end

      it 'returns true for admin' do
        membership = build(:membership, role: :admin)
        expect(membership.admin_or_owner?).to be true
      end

      it 'returns false for member' do
        membership = build(:membership, role: :member)
        expect(membership.admin_or_owner?).to be false
      end
    end

    describe '#can_manage_members?' do
      it 'returns true for owners and admins' do
        expect(build(:membership, role: :owner).can_manage_members?).to be true
        expect(build(:membership, role: :admin).can_manage_members?).to be true
      end

      it 'returns false for members and guests' do
        expect(build(:membership, role: :member).can_manage_members?).to be false
        expect(build(:membership, role: :guest).can_manage_members?).to be false
      end
    end
  end

  describe 'invitation workflow' do
    describe '.invite!' do
      let(:account) { create(:account) }
      let(:inviter) { create(:user) }

      it 'creates a pending membership with invitation details' do
        membership = Membership.invite!(
          account: account,
          email: 'newuser@example.com',
          role: :member,
          invited_by: inviter
        )

        expect(membership).to be_persisted
        expect(membership.invitation_email).to eq('newuser@example.com')
        expect(membership.invitation_token).to be_present
        expect(membership.invited_at).to be_present
        expect(membership.invited_by).to eq(inviter)
        expect(membership.user).to be_nil
      end
    end

    describe '#pending_invitation?' do
      it 'returns true when invitation is pending' do
        membership = build(:membership, :invited)
        expect(membership.pending_invitation?).to be true
      end

      it 'returns false when invitation is accepted' do
        membership = build(:membership, :accepted)
        expect(membership.pending_invitation?).to be false
      end
    end

    describe '#accept_invitation!' do
      let(:user) { create(:user) }
      let(:membership) { create(:membership, :invited) }

      it 'associates the user and clears invitation token' do
        membership.accept_invitation!(user)

        expect(membership.user).to eq(user)
        expect(membership.accepted_at).to be_present
        expect(membership.invitation_token).to be_nil
      end
    end

    describe '#invitation_expired?' do
      it 'returns true after 7 days' do
        membership = build(:membership, invited_at: 8.days.ago)
        expect(membership.invitation_expired?).to be true
      end

      it 'returns false within 7 days' do
        membership = build(:membership, invited_at: 3.days.ago)
        expect(membership.invitation_expired?).to be false
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only accepted memberships' do
        accepted = create(:membership, :accepted)
        _pending = create(:membership, :invited)

        expect(Membership.active).to include(accepted)
        expect(Membership.active).not_to include(_pending)
      end
    end

    describe '.pending' do
      it 'returns only pending invitations' do
        _accepted = create(:membership, :accepted)
        pending = create(:membership, :invited)

        expect(Membership.pending).to include(pending)
        expect(Membership.pending).not_to include(_accepted)
      end
    end
  end

  describe 'ownership protection' do
    it 'prevents changing owner to a lower role' do
      membership = create(:membership, role: :owner)
      membership.role = :member

      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to include("cannot be changed for the account owner")
    end

    it 'prevents destroying the owner membership' do
      membership = create(:membership, role: :owner)

      expect { membership.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
