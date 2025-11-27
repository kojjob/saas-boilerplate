# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(membership)
    @membership = membership
    @account = membership.account
    @inviter = membership.invited_by
    @accept_url = accept_invitation_url(@membership.invitation_token)

    mail(
      to: @membership.invitation_email,
      subject: "You've been invited to join #{@account.name}"
    )
  end
end
