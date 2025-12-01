# frozen_string_literal: true

# Base class for service objects
#
# Service objects encapsulate complex business logic that doesn't belong
# in models or controllers. They follow a simple pattern:
#
# Usage:
#   result = MyService.call(arg1, arg2)
#   if result.success?
#     # handle success, access result.data
#   else
#     # handle failure, access result.error
#   end
#
# Creating a service:
#   class MyService < ApplicationService
#     def initialize(user, params)
#       @user = user
#       @params = params
#     end
#
#     def call
#       # do work
#       success(data: { user: @user })
#     rescue SomeError => e
#       failure(e.message)
#     end
#   end
#
class ApplicationService
  # Result object returned by services
  class Result
    attr_reader :data, :error, :errors

    def initialize(success:, data: {}, error: nil, errors: [])
      @success = success
      @data = data
      @error = error
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    # Allow accessing data keys as methods
    def method_missing(method_name, *args, &block)
      if data.is_a?(Hash) && data.key?(method_name)
        data[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      (data.is_a?(Hash) && data.key?(method_name)) || super
    end
  end

  # Class method to instantiate and call the service
  def self.call(...)
    new(...).call
  end

  # Subclasses must implement this method
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  # Return a successful result
  # @param data [Hash] optional data to include in the result
  # @return [Result]
  def success(data = {})
    Result.new(success: true, data: data)
  end

  # Return a failed result
  # @param error [String] error message
  # @param errors [Array] optional array of error messages
  # @return [Result]
  def failure(error, errors: [])
    Result.new(success: false, error: error, errors: errors)
  end

  # Wrap ActiveRecord operations in a transaction
  # @yield block to execute in transaction
  # @return [Result]
  def with_transaction(&block)
    ActiveRecord::Base.transaction(&block)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message, errors: e.record.errors.full_messages)
  rescue StandardError => e
    Rails.logger.error("[#{self.class}] Error: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    failure("An unexpected error occurred")
  end
end
