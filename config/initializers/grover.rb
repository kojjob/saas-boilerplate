# frozen_string_literal: true

Grover.configure do |config|
  # Set default options for PDF generation
  config.options = {
    format: "Letter",
    margin: {
      top: "0.5in",
      bottom: "0.5in",
      left: "0.5in",
      right: "0.5in"
    },
    print_background: true,
    prefer_css_page_size: true,
    emulate_media: "print",
    display_url: false,
    wait_until: "networkidle0"
  }

  # Use chromium/puppeteer for rendering
  config.use_pdf_middleware = false
end
