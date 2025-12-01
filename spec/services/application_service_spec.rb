# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationService do
  # Test subclass for testing the base class
  class TestSuccessService < ApplicationService
    def initialize(value)
      @value = value
    end

    def call
      success(result: @value * 2)
    end
  end

  class TestFailureService < ApplicationService
    def initialize(message)
      @message = message
    end

    def call
      failure(@message, errors: ["Error 1", "Error 2"])
    end
  end

  class TestTransactionService < ApplicationService
    def initialize(should_fail:)
      @should_fail = should_fail
    end

    def call
      with_transaction do
        raise ActiveRecord::RecordInvalid.new(User.new) if @should_fail

        success(completed: true)
      end
    end
  end

  class TestNotImplementedService < ApplicationService
  end

  describe ".call" do
    it "instantiates and calls the service" do
      result = TestSuccessService.call(5)
      expect(result).to be_success
      expect(result.data[:result]).to eq(10)
    end
  end

  describe ApplicationService::Result do
    describe "#success?" do
      it "returns true for successful results" do
        result = ApplicationService::Result.new(success: true)
        expect(result).to be_success
      end

      it "returns false for failed results" do
        result = ApplicationService::Result.new(success: false)
        expect(result).not_to be_success
      end
    end

    describe "#failure?" do
      it "returns true for failed results" do
        result = ApplicationService::Result.new(success: false)
        expect(result).to be_failure
      end

      it "returns false for successful results" do
        result = ApplicationService::Result.new(success: true)
        expect(result).not_to be_failure
      end
    end

    describe "#data" do
      it "returns the data hash" do
        result = ApplicationService::Result.new(success: true, data: { foo: "bar" })
        expect(result.data).to eq({ foo: "bar" })
      end
    end

    describe "#error" do
      it "returns the error message" do
        result = ApplicationService::Result.new(success: false, error: "Something went wrong")
        expect(result.error).to eq("Something went wrong")
      end
    end

    describe "#errors" do
      it "returns the errors array" do
        result = ApplicationService::Result.new(success: false, errors: ["Error 1", "Error 2"])
        expect(result.errors).to eq(["Error 1", "Error 2"])
      end
    end

    describe "method_missing for data access" do
      it "allows accessing data keys as methods" do
        result = ApplicationService::Result.new(success: true, data: { user: "John", count: 5 })
        expect(result.user).to eq("John")
        expect(result.count).to eq(5)
      end

      it "raises NoMethodError for unknown keys" do
        result = ApplicationService::Result.new(success: true, data: { user: "John" })
        expect { result.unknown_key }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#success" do
    it "returns a successful result with data" do
      result = TestSuccessService.call(5)
      expect(result).to be_success
      expect(result.data[:result]).to eq(10)
    end
  end

  describe "#failure" do
    it "returns a failed result with error and errors array" do
      result = TestFailureService.call("Test error")
      expect(result).to be_failure
      expect(result.error).to eq("Test error")
      expect(result.errors).to eq(["Error 1", "Error 2"])
    end
  end

  describe "#with_transaction" do
    it "returns success when transaction completes" do
      result = TestTransactionService.call(should_fail: false)
      expect(result).to be_success
      expect(result.data[:completed]).to be true
    end

    it "returns failure when ActiveRecord::RecordInvalid is raised" do
      result = TestTransactionService.call(should_fail: true)
      expect(result).to be_failure
      expect(result.error).to include("Validation failed")
    end
  end

  describe "#call (not implemented)" do
    it "raises NotImplementedError when not implemented" do
      expect { TestNotImplementedService.call }.to raise_error(NotImplementedError)
    end
  end
end
