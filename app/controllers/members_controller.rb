# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :set_membership, only: [:update, :destroy]

  def index
    authorize Membership
    @memberships = policy_scope(Membership).includes(:user, :invited_by).order(created_at: :asc)
    @current_membership = @account.memberships.find_by(user: current_user)
  end

  def update
    authorize @membership

    new_role = membership_params[:role]

    # Prevent changing to owner role via update
    if new_role == 'owner'
      render json: { error: 'Cannot assign owner role' }, status: :unprocessable_entity
      return
    end

    if @membership.update(role: new_role)
      redirect_to account_members_path, notice: "#{@membership.user.full_name}'s role has been updated."
    else
      render json: { error: @membership.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @membership

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

    # Use policy to check if user can leave (destroy their own membership)
    authorize membership, :destroy?

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
end
