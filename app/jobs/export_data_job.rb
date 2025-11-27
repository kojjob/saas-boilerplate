# frozen_string_literal: true

# Job to export user data asynchronously
# Supports multiple export types and generates CSV/JSON exports
class ExportDataJob < ApplicationJob
  queue_as :exports

  SUPPORTED_EXPORT_TYPES = %w[users accounts activity_logs].freeze

  # @param user_id [Integer] The ID of the user requesting the export
  # @param export_type [String] The type of data to export
  # @param options [Hash] Additional export options
  def perform(user_id, export_type, options = {})
    user = User.find_by(id: user_id)

    unless user
      Rails.logger.warn "[ExportDataJob] Skipped - user #{user_id} not found"
      return { success: false, error: "User not found" }
    end

    unless SUPPORTED_EXPORT_TYPES.include?(export_type)
      Rails.logger.warn "[ExportDataJob] Skipped - invalid export type: #{export_type}"
      return { success: false, error: "Invalid export type" }
    end

    data = generate_export(user, export_type, options)

    Rails.logger.info "[ExportDataJob] Generated #{export_type} export for user #{user_id}"

    { success: true, data: data, export_type: export_type }
  end

  private

  def generate_export(user, export_type, options)
    case export_type
    when "users"
      export_users(user, options)
    when "accounts"
      export_accounts(user, options)
    when "activity_logs"
      export_activity_logs(user, options)
    end
  end

  def export_users(user, _options)
    # Export user's own data
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def export_accounts(user, _options)
    # Export user's account memberships
    user.memberships.includes(:account).map do |membership|
      {
        account_id: membership.account_id,
        account_name: membership.account.name,
        role: membership.role,
        joined_at: membership.created_at
      }
    end
  end

  def export_activity_logs(user, _options)
    # Export user's activity logs (from Audited)
    user.own_and_associated_audits.limit(1000).map do |audit|
      {
        action: audit.action,
        auditable_type: audit.auditable_type,
        auditable_id: audit.auditable_id,
        created_at: audit.created_at
      }
    end
  end
end
