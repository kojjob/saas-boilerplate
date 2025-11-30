# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :create ]

      def create
        if params[:email].blank? || params[:password].blank?
          return render_bad_request("Email and password are required")
        end

        user = User.find_by(email: params[:email].downcase)

        if user&.authenticate(params[:password])
          api_token = ApiToken.generate_for(user, name: params[:name])

          render json: {
            token: api_token.token,
            expires_at: api_token.expires_at,
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name
            }
          }, status: :created
        else
          render_unauthorized("Invalid email or password")
        end
      end

      def destroy
        current_api_token.revoke!
        render_no_content
      end
    end
  end
end
