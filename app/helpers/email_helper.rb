# frozen_string_literal: true

module EmailHelper
  # Primary brand color for buttons
  DEFAULT_BUTTON_COLOR = "#4F46E5"  # Indigo-600

  # Generate a styled email button
  def email_button(text, url, color: DEFAULT_BUTTON_COLOR)
    content_tag :table, border: "0", cellpadding: "0", cellspacing: "0", role: "presentation",
                        style: "border-collapse: separate; line-height: 100%;" do
      content_tag :tbody do
        content_tag :tr do
          content_tag :td, align: "center", bgcolor: color, role: "presentation", valign: "middle",
                           style: "border: none; border-radius: 6px; cursor: auto; padding: 12px 24px; background: #{color};" do
            link_to text, url, rel: "noopener", target: "_blank",
                              style: "background: #{color}; color: #ffffff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 16px; font-weight: 600; line-height: 120%; text-decoration: none; text-transform: none; padding: 0; display: inline-block;"
          end
        end
      end
    end
  end

  # Generate a simple text link
  def email_text_link(text, url, color: DEFAULT_BUTTON_COLOR)
    link_to text, url, style: "color: #{color}; text-decoration: underline;"
  end

  # Generate a styled heading
  def email_heading(text, level: 1)
    sizes = { 1 => "28px", 2 => "24px", 3 => "20px", 4 => "18px" }
    font_size = sizes[level] || "28px"

    content_tag "h#{level}", text,
                style: "margin: 0 0 16px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: #{font_size}; font-weight: 700; line-height: 1.25; color: #1a1a1a;"
  end

  # Generate a styled paragraph
  def email_paragraph(text)
    content_tag :p, text,
                style: "margin: 0 0 16px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 16px; line-height: 1.625; color: #374151;"
  end

  # Generate a horizontal divider
  def email_divider
    tag :hr, style: "border: 0; border-top: 1px solid #e5e7eb; margin: 24px 0;"
  end

  # Generate a vertical spacer
  def email_spacer(height: "24px")
    content_tag :div, "&nbsp;".html_safe, style: "height: #{height}; line-height: #{height}; font-size: 1px;"
  end

  # App logo URL
  def app_logo_url
    # Use an asset URL or a default placeholder
    "https://via.placeholder.com/150x50?text=Logo"
  end

  # Support email address
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "support@example.com")
  end

  # Company name
  def company_name
    ENV.fetch("COMPANY_NAME", "SaaS Boilerplate")
  end

  # Copyright year
  def copyright_year
    Time.current.year
  end

  # Email footer text
  def email_footer_text
    "#{company_name} - All rights reserved #{copyright_year}"
  end

  # Unsubscribe link (if applicable)
  def email_unsubscribe_url
    # This would be customized per user
    "#"
  end

  # Generate an info box (for notices, warnings, etc.)
  def email_info_box(text, type: :info)
    colors = {
      info: { bg: "#EFF6FF", border: "#3B82F6", text: "#1E40AF" },
      success: { bg: "#F0FDF4", border: "#22C55E", text: "#166534" },
      warning: { bg: "#FFFBEB", border: "#F59E0B", text: "#92400E" },
      error: { bg: "#FEF2F2", border: "#EF4444", text: "#991B1B" }
    }

    style = colors[type] || colors[:info]

    content_tag :div, text,
                style: "background-color: #{style[:bg]}; border-left: 4px solid #{style[:border]}; color: #{style[:text]}; padding: 16px; margin: 16px 0; font-size: 14px; line-height: 1.5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;"
  end

  # Generate a feature list item
  def email_list_item(text, icon: "checkmark")
    content_tag :tr do
      content_tag(:td, "#{icon == 'checkmark' ? '&#10003;' : '&bull;'}".html_safe,
                  style: "padding: 4px 12px 4px 0; color: #22C55E; font-size: 16px; vertical-align: top;") +
        content_tag(:td, text,
                    style: "padding: 4px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 15px; line-height: 1.5; color: #374151;")
    end
  end
end
