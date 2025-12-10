# frozen_string_literal: true

module Pdf
  # Generates PDF estimates using HTML templates and Grover
  #
  # This service renders an estimate as a professional PDF document
  # by converting the estimate HTML template to PDF format.
  #
  # @example Generate PDF for an estimate
  #   result = Pdf::EstimatePdfGenerator.call(estimate: estimate)
  #   if result.success?
  #     send_data result.pdf, filename: "Estimate-#{estimate.estimate_number}.pdf"
  #   end
  #
  class EstimatePdfGenerator < ApplicationService
    attr_reader :estimate

    def initialize(estimate:)
      @estimate = estimate
    end

    def call
      validate_estimate!
      html_content = render_estimate_html
      pdf_result = generate_pdf(html_content)

      if pdf_result.success?
        success(pdf: pdf_result.data[:pdf], filename: filename)
      else
        failure(pdf_result.error)
      end
    rescue StandardError => e
      Rails.logger.error("[EstimatePdfGenerator] Error generating PDF for Estimate ##{estimate&.id}: #{e.message}")
      failure(e.message)
    end

    def filename
      "Estimate-#{estimate.estimate_number}.pdf"
    end

    private

    def validate_estimate!
      raise ArgumentError, "Estimate is required" if estimate.blank?
      raise ArgumentError, "Estimate must be persisted" unless estimate.persisted?
    end

    def render_estimate_html
      renderer = ApplicationController.renderer.new(
        http_host: Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
      )

      renderer.render(
        template: "estimates/pdf",
        layout: "pdf",
        assigns: { estimate: estimate }
      )
    end

    def generate_pdf(html_content)
      HtmlToPdfGenerator.call(
        html: html_content,
        options: pdf_options
      )
    end

    def pdf_options
      {
        format: "Letter",
        print_background: true,
        prefer_css_page_size: true,
        margin: {
          top: "0.5in",
          bottom: "0.5in",
          left: "0.5in",
          right: "0.5in"
        }
      }
    end
  end
end
