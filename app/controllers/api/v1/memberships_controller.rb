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
        membership = @account.memberships.build(membership_params)

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
        params.require(:membership).permit(:user_id, :role)
      end

      def membership_update_params
        params.require(:membership).permit(:role)
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
