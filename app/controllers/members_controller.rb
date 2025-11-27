# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :set_membership, only: [:update, :destroy]
  before_action :authorize_member_management, only: [:update, :destroy]

  def index
    @memberships = @account.memberships.includes(:user, :invited_by).order(created_at: :asc)
    @current_membership = @account.memberships.find_by(user: current_user)
  end

  def update
    new_role = membership_params[:role]

    # Prevent changing to owner role
    if new_role == 'owner'
      render json: { error: 'Cannot assign owner role' }, status: :unprocessable_entity
      return
    end

    # Prevent owner from changing their own role
    if @membership.owner?
      render json: { error: 'Cannot change owner role' }, status: :unprocessable_entity
      return
    end

    # Admins cannot change other admin roles (only owners can)
    user_membership = @account.memberships.find_by(user: current_user)
    if user_membership.admin? && @membership.admin?
      render json: { error: 'Admins cannot change other admin roles' }, status: :unprocessable_entity
      return
    end

    if @membership.update(role: new_role)
      redirect_to account_members_path, notice: "#{@membership.user.full_name}'s role has been updated."
    else
      render json: { error: @membership.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    # Prevent owner from removing themselves
    if @membership.owner?
      render json: { error: 'Cannot remove the account owner' }, status: :unprocessable_entity
      return
    end

    # Prevent admins from removing other admins
    user_membership = @account.memberships.find_by(user: current_user)
    if user_membership.admin? && @membership.admin?
      render json: { error: 'Admins cannot remove other admins' }, status: :unprocessable_entity
      return
    end

    member_name = @membership.user&.full_name || @membership.invitation_email
    @membership.destroy

    redirect_to account_members_path, notice: "#{member_name} has been removed from the team."
  end

  def leave
    membership = @account.memberships.find_by(user: current_user)

    if membership.nil?
      redirect_to dashboard_path, alert: 'You are not a member of this account.'
      return
    end

    if membership.owner?
      redirect_to account_members_path, alert: 'Account owners cannot leave. Transfer ownership first.'
      return
    end

    membership.destroy

    # Switch to another account if available
    other_membership = current_user.memberships.first
    if other_membership
      set_tenant_for_user(current_user, other_membership.account)
    end

    redirect_to dashboard_path, notice: 'You have left the team.'
  end

  private

  def set_account
    @account = current_account
  end

  def set_membership
    @membership = @account.memberships.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:role)
  end

  def authorize_member_management
    user_membership = @account.memberships.find_by(user: current_user)
    unless user_membership&.can_manage_members?
      redirect_to dashboard_path, alert: 'You do not have permission to manage team members.'
    end
  end
end
