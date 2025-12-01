# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      before_action :set_account, only: [ :show, :update ]
      before_action :authorize_account_access!, only: [ :show, :update ]
      before_action :authorize_account_admin!, only: [ :update ]

      def index
        accounts = current_api_user.accounts.kept.includes(:plan)

        render_success(accounts.map { |account| account_data(account) })
      end

      def show
        render_success(account_data(@account))
      end

      def update
        if @account.update(account_params)
          render_success(account_data(@account))
        else
          render json: {
            error: "Validation failed",
            errors: @account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_account
        @account = Account.kept.find(params[:id])
      end

      def authorize_account_access!
        unless current_api_user.member_of?(@account)
          render_forbidden("You do not have access to this account")
        end
      end

      def authorize_account_admin!
        unless current_api_user.owner_of?(@account)
          render_forbidden("Only account owners can perform this action")
        end
      end

      def account_params
        params.require(:account).permit(:name)
      end

      def account_data(account)
        {
          id: account.id,
          name: account.name,
          slug: account.slug,
          subscription_status: account.subscription_status,
          trial_ends_at: account.trial_ends_at,
          plan: account.plan ? { id: account.plan.id, name: account.plan.name } : nil,
          created_at: account.created_at,
          updated_at: account.updated_at
        }
      end
    end
  end
end
