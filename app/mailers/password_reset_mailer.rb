# frozen_string_literal: true

class PasswordResetMailer < ApplicationMailer
  def reset_email(user)
    @user = user
    @reset_url = edit_password_reset_url(token: user.reset_password_token)

    mail(
      to: user.email,
      subject: "Reset your password"
    )
  end
end
