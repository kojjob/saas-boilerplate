# frozen_string_literal: true

module Pdf
  # Generates PDF documents from HTML using Grover (Puppeteer/Chrome)
  #
  # This service renders HTML templates to PDF format, providing pixel-perfect
  # conversion that maintains all CSS styling including Tailwind classes,
  # gradients, shadows, and responsive layouts.
  #
  # @example Generate PDF from HTML string
  #   result = Pdf::HtmlToPdfGenerator.call(html: "<h1>Hello</h1>")
  #   result.pdf # => PDF binary data
  #
  # @example Generate PDF with custom options
  #   result = Pdf::HtmlToPdfGenerator.call(
  #     html: html_content,
  #     options: {
  #       format: "Letter",
  #       print_background: true,
  #       margin: { top: "1in", bottom: "1in" }
  #     }
  #   )
  #
  class HtmlToPdfGenerator < ApplicationService
    DEFAULT_OPTIONS = {
      format: "Letter",
      print_background: true,
      prefer_css_page_size: true,
      margin: {
        top: "0.5in",
        bottom: "0.5in",
        left: "0.5in",
        right: "0.5in"
      }
    }.freeze

    def initialize(html:, options: {})
      @html = html
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def call
      validate_html!
      pdf_data = generate_pdf

      success(pdf: pdf_data)
    rescue StandardError => e
      Rails.logger.error("[HtmlToPdfGenerator] Error generating PDF: #{e.message}")
      failure(e.message)
    end

    private

    attr_reader :html, :options

    def validate_html!
      raise ArgumentError, "HTML content is required" if html.blank?
    end

    def generate_pdf
      Grover.new(html, **grover_options).to_pdf
    end

    def grover_options
      {
        format: options[:format],
        print_background: options[:print_background],
        prefer_css_page_size: options[:prefer_css_page_size],
        margin: options[:margin],
        display_url: false,
        wait_until: "networkidle0"
      }
    end
  end
end
