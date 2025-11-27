# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  describe "queue configuration" do
    it "defaults to the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  describe "retry configuration" do
    it "retries on ActiveRecord::Deadlocked" do
      retry_config = described_class.rescue_handlers.find { |handler| handler[0] == "ActiveRecord::Deadlocked" }
      expect(retry_config).to be_present
    end

    it "retries on ActiveRecord::ConnectionNotEstablished" do
      retry_config = described_class.rescue_handlers.find { |handler| handler[0] == "ActiveRecord::ConnectionNotEstablished" }
      expect(retry_config).to be_present
    end
  end

  describe "discard configuration" do
    it "discards on ActiveJob::DeserializationError" do
      discard_config = described_class.rescue_handlers.find { |handler| handler[0] == "ActiveJob::DeserializationError" }
      expect(discard_config).to be_present
    end
  end
end
