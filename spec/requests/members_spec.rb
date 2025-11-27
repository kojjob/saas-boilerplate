# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Members', type: :request do
  let(:owner) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:owner_membership) { create(:membership, :owner, user: owner, account: account) }

  describe 'GET /account/members' do
    context 'when signed in' do
      before { sign_in(owner) }

      it 'shows the team members page' do
        get account_members_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Team Members')
        expect(response.body).to include(owner.full_name)
      end

      it 'shows pending invitations' do
        pending_invite = Membership.invite!(
          account: account,
          email: 'pending@example.com',
          role: 'member',
          invited_by: owner
        )

        get account_members_path

        expect(response.body).to include('pending@example.com')
        expect(response.body).to include('Pending')
      end

      it 'shows all team members with roles' do
        member = create(:user, :confirmed)
        create(:membership, user: member, account: account, role: :member)

        get account_members_path

        expect(response.body).to include(CGI.escapeHTML(member.full_name))
        expect(response.body).to include('Member')
        expect(response.body).to include('Owner')
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in' do
        get account_members_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe 'PATCH /account/members/:id' do
    let(:member) { create(:user, :confirmed) }
    let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }

    context 'when signed in as owner' do
      before { sign_in(owner) }

      it 'updates member role' do
        patch account_member_path(member_membership), params: { membership: { role: 'admin' } }

        expect(member_membership.reload.role).to eq('admin')
        expect(response).to redirect_to(account_members_path)
      end

      it 'does not allow changing to owner role' do
        patch account_member_path(member_membership), params: { membership: { role: 'owner' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(member_membership.reload.role).to eq('member')
      end

      it 'cannot change own owner role' do
        patch account_member_path(owner_membership), params: { membership: { role: 'admin' } }

        expect(response).to redirect_to(dashboard_path)
        expect(owner_membership.reload.role).to eq('owner')
      end
    end

    context 'when signed in as admin' do
      let(:admin) { create(:user, :confirmed) }
      let!(:admin_membership) { create(:membership, user: admin, account: account, role: :admin) }

      before { sign_in(admin) }

      it 'can update member roles' do
        patch account_member_path(member_membership), params: { membership: { role: 'guest' } }

        expect(member_membership.reload.role).to eq('guest')
      end

      it 'cannot change owner role' do
        patch account_member_path(owner_membership), params: { membership: { role: 'admin' } }

        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when signed in as member' do
      before { sign_in(member) }

      it 'denies access' do
        another_member = create(:user, :confirmed)
        another_membership = create(:membership, user: another_member, account: account)

        patch account_member_path(another_membership), params: { membership: { role: 'admin' } }

        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'DELETE /account/members/:id' do
    let(:member) { create(:user, :confirmed) }
    let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }

    context 'when signed in as owner' do
      before { sign_in(owner) }

      it 'removes the member' do
        expect {
          delete account_member_path(member_membership)
        }.to change(Membership, :count).by(-1)
      end

      it 'redirects with success message' do
        delete account_member_path(member_membership)

        expect(response).to redirect_to(account_members_path)
        follow_redirect!
        expect(response.body).to include('removed')
      end

      it 'cannot remove self as owner' do
        delete account_member_path(owner_membership)

        expect(response).to redirect_to(dashboard_path)
        expect(Membership.exists?(owner_membership.id)).to be true
      end
    end

    context 'when member leaves' do
      before { sign_in(member) }

      it 'allows member to leave account' do
        delete leave_account_member_path(member_membership)

        expect(response).to redirect_to(dashboard_path)
        expect(Membership.exists?(member_membership.id)).to be false
      end
    end
  end
end
