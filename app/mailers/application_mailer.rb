# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM_EMAIL = ENV.fetch("DEFAULT_FROM_EMAIL", "noreply@example.com")
  DEFAULT_FROM_NAME = ENV.fetch("DEFAULT_FROM_NAME", "SaaS Boilerplate")

  default from: "#{DEFAULT_FROM_NAME} <#{DEFAULT_FROM_EMAIL}>"
  layout "mailer"

  # Include email helpers for use in mailer views
  helper EmailHelper

  # Make helper methods available in mailers
  helper_method :email_button, :email_text_link, :email_heading, :email_paragraph,
                :email_divider, :email_spacer, :app_logo_url, :support_email,
                :company_name, :copyright_year, :email_footer_text,
                :email_info_box, :email_list_item

  private

  # Wrapper methods to make helpers available in mailer classes
  def email_button(text, url, color: EmailHelper::DEFAULT_BUTTON_COLOR)
    helpers.email_button(text, url, color: color)
  end

  def email_text_link(text, url, color: EmailHelper::DEFAULT_BUTTON_COLOR)
    helpers.email_text_link(text, url, color: color)
  end

  def email_heading(text, level: 1)
    helpers.email_heading(text, level: level)
  end

  def email_paragraph(text)
    helpers.email_paragraph(text)
  end

  def email_divider
    helpers.email_divider
  end

  def email_spacer(height: "24px")
    helpers.email_spacer(height: height)
  end

  def app_logo_url
    helpers.app_logo_url
  end

  def support_email
    helpers.support_email
  end

  def company_name
    helpers.company_name
  end

  def copyright_year
    helpers.copyright_year
  end

  def email_footer_text
    helpers.email_footer_text
  end

  def email_info_box(text, type: :info)
    helpers.email_info_box(text, type: type)
  end

  def email_list_item(text, icon: "checkmark")
    helpers.email_list_item(text, icon: icon)
  end
end
