# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      protected

      def current_api_user
        @current_api_user ||= current_api_token&.user
      end

      def current_api_token
        @current_api_token ||= authenticate_token
      end

      private

      def authenticate_api_user!
        unless current_api_user
          render_unauthorized("Invalid or missing API token")
        end
      end

      def authenticate_token
        authenticate_with_http_token do |token, _options|
          ApiToken.authenticate(token)
        end
      end

      def render_success(data, status: :ok)
        render json: { data: data }, status: status
      end

      def render_created(data)
        render json: { data: data }, status: :created
      end

      def render_no_content
        head :no_content
      end

      def render_unauthorized(message = "Unauthorized")
        render json: { error: message }, status: :unauthorized
      end

      def render_forbidden(message = "Forbidden")
        render json: { error: message }, status: :forbidden
      end

      def render_not_found(exception = nil)
        message = exception&.message || "Resource not found"
        render json: { error: message }, status: :not_found
      end

      def render_unprocessable_entity(exception)
        render json: {
          error: "Validation failed",
          errors: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def render_bad_request(exception_or_message = nil)
        message = case exception_or_message
        when String then exception_or_message
        when nil then "Bad request"
        else exception_or_message.message
        end
        render json: { error: message }, status: :bad_request
      end
    end
  end
end
