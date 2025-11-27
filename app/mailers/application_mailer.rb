# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM_EMAIL = ENV.fetch("DEFAULT_FROM_EMAIL", "noreply@example.com")
  DEFAULT_FROM_NAME = ENV.fetch("DEFAULT_FROM_NAME", "SaaS Boilerplate")

  default from: "#{DEFAULT_FROM_NAME} <#{DEFAULT_FROM_EMAIL}>"
  layout "mailer"

  # Include email helpers for use in mailer views
  helper EmailHelper

  # Make helper methods available in mailers via helper_method
  # These methods delegate to a helper instance so they're available in templates
  helper_method :email_button, :email_text_link, :email_heading, :email_paragraph,
                :email_divider, :email_spacer, :app_logo_url, :support_email,
                :company_name, :copyright_year, :email_footer_text,
                :email_info_box, :email_list_item

  private

  # Create a helper instance for delegation
  # Include ActionView helpers that EmailHelper depends on
  def email_helper
    @email_helper ||= Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Context
      include EmailHelper
    end.new
  end

  # Wrapper methods to make helpers available in mailer classes
  def email_button(text, url, color: EmailHelper::DEFAULT_BUTTON_COLOR)
    email_helper.email_button(text, url, color: color)
  end

  def email_text_link(text, url, color: EmailHelper::DEFAULT_BUTTON_COLOR)
    email_helper.email_text_link(text, url, color: color)
  end

  def email_heading(text, level: 1)
    email_helper.email_heading(text, level: level)
  end

  def email_paragraph(text)
    email_helper.email_paragraph(text)
  end

  def email_divider
    email_helper.email_divider
  end

  def email_spacer(height: "24px")
    email_helper.email_spacer(height: height)
  end

  def app_logo_url
    email_helper.app_logo_url
  end

  def support_email
    email_helper.support_email
  end

  def company_name
    email_helper.company_name
  end

  def copyright_year
    email_helper.copyright_year
  end

  def email_footer_text
    email_helper.email_footer_text
  end

  def email_info_box(text, type: :info)
    email_helper.email_info_box(text, type: type)
  end

  def email_list_item(text, icon: "checkmark")
    email_helper.email_list_item(text, icon: icon)
  end
end
