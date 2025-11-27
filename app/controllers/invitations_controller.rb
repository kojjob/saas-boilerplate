# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :authorize_invitation_management
  before_action :set_invitation, only: [ :destroy, :resend ]

  def new
    authorize Membership, :invite?
    @invitation = Membership.new
    @available_roles = available_roles
  end

  def create
    authorize Membership, :invite?

    email = invitation_params[:invitation_email]&.downcase&.strip

    # Check for existing membership
    existing_user = User.find_by(email: email)
    if existing_user && @account.memberships.exists?(user: existing_user)
      flash.now[:alert] = "This user is already a member of this account."
      @invitation = Membership.new(invitation_params)
      @available_roles = available_roles
      render :new, status: :unprocessable_entity
      return
    end

    # Check for pending invitation
    if @account.memberships.pending.exists?(invitation_email: email)
      flash.now[:alert] = "An invitation has already been sent to this email address."
      @invitation = Membership.new(invitation_params)
      @available_roles = available_roles
      render :new, status: :unprocessable_entity
      return
    end

    # Validate role
    role = invitation_params[:role]
    unless available_roles.include?(role)
      flash.now[:alert] = "Invalid role selected."
      @invitation = Membership.new(invitation_params)
      @available_roles = available_roles
      render :new, status: :unprocessable_entity
      return
    end

    @invitation = Membership.invite!(
      account: @account,
      email: email,
      role: role,
      invited_by: current_user
    )

    InvitationMailer.invite(@invitation).deliver_later

    redirect_to account_members_path, notice: "Invitation sent to #{email}."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.join(", ")
    @invitation = Membership.new(invitation_params)
    @available_roles = available_roles
    render :new, status: :unprocessable_entity
  end

  def destroy
    authorize @invitation, :cancel_invitation?

    email = @invitation.invitation_email
    @invitation.destroy

    redirect_to account_members_path, notice: "Invitation to #{email} has been cancelled."
  end

  def resend
    authorize @invitation, :resend_invitation?

    if @invitation.invitation_expired?
      @invitation.resend_invitation!
    end

    InvitationMailer.invite(@invitation).deliver_later

    redirect_to account_members_path, notice: "Invitation resent to #{@invitation.invitation_email}."
  end

  private

  def set_account
    @account = current_account
  end

  def set_invitation
    @invitation = @account.memberships.pending.find(params[:id])
  end

  def invitation_params
    params.require(:membership).permit(:invitation_email, :role)
  end

  def authorize_invitation_management
    membership = @account.memberships.find_by(user: current_user)
    unless membership&.can_manage_members?
      redirect_to dashboard_path, alert: "You do not have permission to manage invitations."
    end
  end

  def available_roles
    user_membership = @account.memberships.find_by(user: current_user)
    if user_membership&.owner?
      %w[admin member guest]
    else
      %w[member guest]
    end
  end
end
