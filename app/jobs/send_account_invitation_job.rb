# frozen_string_literal: true

# Job to send account invitation emails asynchronously
class SendAccountInvitationJob < ApplicationJob
  queue_as :default

  # Retry on network-related errors
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  retry_on Errno::ECONNRESET, wait: 5.seconds, attempts: 3

  # @param membership_id [Integer] The ID of the membership to send invitation for
  # @param inviter_id [Integer] The ID of the user who sent the invitation (optional, uses membership.invited_by)
  def perform(membership_id, _inviter_id = nil)
    membership = Membership.find_by(id: membership_id)

    unless membership
      Rails.logger.warn "[SendAccountInvitationJob] Skipped - membership #{membership_id} not found"
      return
    end

    unless membership.invitation_email.present?
      Rails.logger.warn "[SendAccountInvitationJob] Skipped - membership #{membership_id} has no invitation_email"
      return
    end

    # The InvitationMailer.invite method takes only the membership
    # It extracts the inviter from membership.invited_by
    InvitationMailer.invite(membership).deliver_now

    Rails.logger.info "[SendAccountInvitationJob] Sent invitation to #{membership.invitation_email} for account #{membership.account_id}"
  end
end
