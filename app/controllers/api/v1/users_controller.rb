# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def me
        render_success(user_data(current_api_user))
      end

      def update
        if current_api_user.update(user_params)
          render_success(user_data(current_api_user))
        else
          render json: {
            error: "Validation failed",
            errors: current_api_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email)
      end

      def user_data(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          confirmed: user.confirmed?,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end
