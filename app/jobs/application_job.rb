# frozen_string_literal: true

# Base class for all application jobs
# Provides common configuration for retry behavior, error handling, and logging
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Retry jobs that failed due to connection issues
  retry_on ActiveRecord::ConnectionNotEstablished, wait: :polynomially_longer, attempts: 5

  # Discard jobs when the underlying record is no longer available
  discard_on ActiveJob::DeserializationError

  # Default queue is 'default'
  queue_as :default

  # Hook for logging job start
  before_perform do |job|
    Rails.logger.info "[Job Start] #{job.class.name} (ID: #{job.job_id})"
  end

  # Hook for logging job completion
  after_perform do |job|
    Rails.logger.info "[Job Complete] #{job.class.name} (ID: #{job.job_id})"
  end

  # Hook for logging job failures
  rescue_from(StandardError) do |exception|
    Rails.logger.error "[Job Failed] #{self.class.name} (ID: #{job_id}): #{exception.message}"
    Rails.logger.error exception.backtrace&.first(10)&.join("\n")
    raise exception
  end
end
