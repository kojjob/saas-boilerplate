# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_account
      before_action :authorize_account_access!
      before_action :authorize_account_owner!, only: [ :create, :update, :destroy ]
      before_action :set_membership, only: [ :update, :destroy ]

      def index
        memberships = @account.memberships.includes(:user)

        render_success(memberships.map { |m| membership_data(m) })
      end

      def create
        # Look up user by email instead of accepting user_id directly
        user = User.kept.find_by(email: membership_params[:email]&.downcase)

        unless user
          render json: { error: "User not found with that email" }, status: :not_found
          return
        end

        # Check if user is already a member
        if @account.memberships.exists?(user: user)
          render json: { error: "User is already a member of this account" }, status: :unprocessable_entity
          return
        end

        membership = @account.memberships.build(
          user: user,
          role: membership_params[:role] || "member"
        )

        if membership.save
          render_created(membership_data(membership))
        else
          render json: {
            error: "Validation failed",
            errors: membership.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        if @membership.update(membership_update_params)
          render_success(membership_data(@membership))
        else
          render json: {
            error: "Validation failed",
            errors: @membership.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @membership.destroy!
        render_no_content
      end

      private

      def set_account
        @account = Account.kept.find(params[:account_id])
      end

      def set_membership
        @membership = @account.memberships.find(params[:id])
      end

      def authorize_account_access!
        unless current_api_user.member_of?(@account)
          render_forbidden("You do not have access to this account")
        end
      end

      def authorize_account_owner!
        unless current_api_user.owner_of?(@account)
          render_forbidden("Only account owners can perform this action")
        end
      end

      def membership_params
        # Only allow role - user_id must be set explicitly from a validated user lookup
        permitted = params.require(:membership).permit(:email, :role)

        # Validate role is in allowed list
        if permitted[:role].present? && !Membership.roles.keys.include?(permitted[:role])
          raise ActionController::BadRequest, "Invalid role"
        end

        permitted
      end

      def membership_update_params
        permitted = params.require(:membership).permit(:role)

        # Validate role is in allowed list and not owner (can't change to owner via API)
        if permitted[:role].present?
          unless Membership.roles.keys.include?(permitted[:role]) && permitted[:role] != "owner"
            raise ActionController::BadRequest, "Invalid role"
          end
        end

        permitted
      end

      def membership_data(membership)
        {
          id: membership.id,
          role: membership.role,
          user: membership.user ? {
            id: membership.user.id,
            email: membership.user.email,
            full_name: membership.user.full_name
          } : nil,
          created_at: membership.created_at,
          updated_at: membership.updated_at
        }
      end
    end
  end
end
