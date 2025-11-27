# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invitations', type: :request do
  let(:owner) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let!(:owner_membership) { create(:membership, :owner, user: owner, account: account) }

  describe 'GET /account/invitations/new' do
    context 'when signed in as owner/admin' do
      before { sign_in(owner) }

      it 'shows the invitation form' do
        get new_account_invitation_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Invite Team Member')
      end
    end

    context 'when signed in as regular member' do
      let(:member) { create(:user, :confirmed) }
      let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }

      before { sign_in(member) }

      it 'redirects with access denied' do
        get new_account_invitation_path

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('permission')
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in' do
        get new_account_invitation_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe 'POST /account/invitations' do
    context 'when signed in as owner/admin' do
      before { sign_in(owner) }

      context 'with valid email' do
        let(:valid_params) { { membership: { invitation_email: 'newmember@example.com', role: 'member' } } }

        it 'creates an invitation' do
          expect {
            post account_invitations_path, params: valid_params
          }.to change(Membership, :count).by(1)
        end

        it 'sends an invitation email' do
          expect {
            post account_invitations_path, params: valid_params
          }.to have_enqueued_mail(InvitationMailer, :invite)
        end

        it 'redirects to team members page' do
          post account_invitations_path, params: valid_params

          expect(response).to redirect_to(account_members_path)
          follow_redirect!
          expect(response.body).to include('Invitation sent')
        end

        it 'creates pending membership with invitation token' do
          post account_invitations_path, params: valid_params

          membership = Membership.last
          expect(membership.invitation_email).to eq('newmember@example.com')
          expect(membership.invitation_token).to be_present
          expect(membership.invited_by).to eq(owner)
          expect(membership.pending_invitation?).to be true
        end
      end

      context 'with invalid email' do
        let(:invalid_params) { { membership: { invitation_email: '', role: 'member' } } }

        it 'does not create invitation' do
          expect {
            post account_invitations_path, params: invalid_params
          }.not_to change(Membership, :count)
        end

        it 'shows error message' do
          post account_invitations_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when email already exists in account' do
        let!(:existing_member) { create(:user, :confirmed, email: 'existing@example.com') }
        let!(:existing_membership) { create(:membership, user: existing_member, account: account) }

        it 'shows error for existing member' do
          post account_invitations_path, params: { membership: { invitation_email: 'existing@example.com', role: 'member' } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('already a member')
        end
      end

      context 'when pending invitation exists for email' do
        before do
          Membership.invite!(account: account, email: 'pending@example.com', role: 'member', invited_by: owner)
        end

        it 'shows error for pending invitation' do
          post account_invitations_path, params: { membership: { invitation_email: 'pending@example.com', role: 'member' } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('already been sent')
        end
      end

      context 'with different roles' do
        it 'allows inviting as admin' do
          post account_invitations_path, params: { membership: { invitation_email: 'admin@example.com', role: 'admin' } }

          expect(Membership.last.role).to eq('admin')
        end

        it 'allows inviting as member' do
          post account_invitations_path, params: { membership: { invitation_email: 'member@example.com', role: 'member' } }

          expect(Membership.last.role).to eq('member')
        end

        it 'does not allow inviting as owner' do
          post account_invitations_path, params: { membership: { invitation_email: 'owner@example.com', role: 'owner' } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('Invalid role')
        end
      end
    end

    context 'when signed in as regular member' do
      let(:member) { create(:user, :confirmed) }
      let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }

      before { sign_in(member) }

      it 'denies access' do
        post account_invitations_path, params: { membership: { invitation_email: 'new@example.com', role: 'member' } }

        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'DELETE /account/invitations/:id' do
    let!(:pending_invitation) do
      Membership.invite!(account: account, email: 'pending@example.com', role: 'member', invited_by: owner)
    end

    context 'when signed in as owner/admin' do
      before { sign_in(owner) }

      it 'cancels the invitation' do
        expect {
          delete account_invitation_path(pending_invitation)
        }.to change(Membership, :count).by(-1)
      end

      it 'redirects with success message' do
        delete account_invitation_path(pending_invitation)

        expect(response).to redirect_to(account_members_path)
        follow_redirect!
        expect(response.body).to include('cancelled')
      end
    end
  end

  describe 'POST /account/invitations/:id/resend' do
    let!(:pending_invitation) do
      Membership.invite!(account: account, email: 'pending@example.com', role: 'member', invited_by: owner)
    end

    context 'when signed in as owner/admin' do
      before { sign_in(owner) }

      it 'resends the invitation email' do
        expect {
          post resend_account_invitation_path(pending_invitation)
        }.to have_enqueued_mail(InvitationMailer, :invite)
      end

      it 'updates the invitation token if expired' do
        # Set the invitation as expired
        pending_invitation.update!(invited_at: 8.days.ago)
        old_token = pending_invitation.invitation_token

        post resend_account_invitation_path(pending_invitation)

        expect(pending_invitation.reload.invitation_token).not_to eq(old_token)
      end

      it 'redirects with success message' do
        post resend_account_invitation_path(pending_invitation)

        expect(response).to redirect_to(account_members_path)
        follow_redirect!
        expect(response.body).to include('resent')
      end
    end
  end

  describe 'GET /invitations/:token/accept' do
    let!(:pending_invitation) do
      Membership.invite!(account: account, email: 'newuser@example.com', role: 'member', invited_by: owner)
    end

    context 'when not signed in' do
      context 'with valid token' do
        it 'shows the accept invitation page' do
          get accept_invitation_path(pending_invitation.invitation_token)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Join')
          expect(response.body).to include(account.name)
        end
      end

      context 'with invalid token' do
        it 'redirects with error' do
          get accept_invitation_path('invalid-token')

          expect(response).to redirect_to(sign_in_path)
          follow_redirect!
          expect(response.body).to include('invalid')
        end
      end

      context 'with expired invitation' do
        before do
          pending_invitation.update!(invited_at: 8.days.ago)
        end

        it 'shows expiration error' do
          get accept_invitation_path(pending_invitation.invitation_token)

          expect(response).to redirect_to(sign_in_path)
          follow_redirect!
          expect(response.body).to include('expired')
        end
      end
    end

    context 'when signed in with matching email' do
      let(:existing_user) { create(:user, :confirmed, email: 'newuser@example.com') }
      let(:user_account) { create(:account) }
      let!(:user_membership) { create(:membership, user: existing_user, account: user_account) }

      before { sign_in(existing_user) }

      it 'shows accept page for existing user' do
        get accept_invitation_path(pending_invitation.invitation_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Join')
      end
    end

    context 'when signed in with different email' do
      let(:different_user) { create(:user, :confirmed, email: 'different@example.com') }
      let(:user_account) { create(:account) }
      let!(:user_membership) { create(:membership, user: different_user, account: user_account) }

      before { sign_in(different_user) }

      it 'shows email mismatch error' do
        get accept_invitation_path(pending_invitation.invitation_token)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('different email')
      end
    end
  end

  describe 'POST /invitations/:token/accept' do
    let!(:pending_invitation) do
      Membership.invite!(account: account, email: 'newuser@example.com', role: 'member', invited_by: owner)
    end

    context 'when existing user accepts' do
      let(:existing_user) { create(:user, :confirmed, email: 'newuser@example.com') }
      let(:user_account) { create(:account) }
      let!(:user_membership) { create(:membership, user: existing_user, account: user_account) }

      before { sign_in(existing_user) }

      it 'accepts the invitation' do
        post accept_invitation_path(pending_invitation.invitation_token)

        expect(pending_invitation.reload.accepted_at).to be_present
        expect(pending_invitation.user).to eq(existing_user)
      end

      it 'redirects to dashboard with success message' do
        post accept_invitation_path(pending_invitation.invitation_token)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('Welcome')
      end
    end

    context 'when new user registers and accepts' do
      let(:registration_params) do
        {
          user: {
            first_name: 'New',
            last_name: 'User',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates user and accepts invitation' do
        expect {
          post accept_invitation_path(pending_invitation.invitation_token), params: registration_params
        }.to change(User, :count).by(1)

        expect(pending_invitation.reload.accepted_at).to be_present
      end

      it 'signs in the new user' do
        post accept_invitation_path(pending_invitation.invitation_token), params: registration_params

        expect(response).to redirect_to(dashboard_path)
      end

      it 'auto-confirms the user' do
        post accept_invitation_path(pending_invitation.invitation_token), params: registration_params

        expect(User.last.confirmed?).to be true
      end
    end

    context 'with invalid token' do
      it 'redirects with error' do
        post accept_invitation_path('invalid-token')

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end
