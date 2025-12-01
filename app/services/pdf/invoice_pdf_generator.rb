# frozen_string_literal: true

module Pdf
  # Generates PDF invoices using HTML templates and Grover
  #
  # This service renders an invoice as a professional PDF document
  # by converting the invoice HTML template to PDF format.
  #
  # @example Generate PDF for an invoice
  #   result = Pdf::InvoicePdfGenerator.call(invoice: invoice)
  #   if result.success?
  #     send_data result.pdf, filename: "Invoice-#{invoice.invoice_number}.pdf"
  #   end
  #
  class InvoicePdfGenerator < ApplicationService
    attr_reader :invoice

    def initialize(invoice:)
      @invoice = invoice
    end

    def call
      validate_invoice!
      html_content = render_invoice_html
      pdf_result = generate_pdf(html_content)

      if pdf_result.success?
        success(pdf: pdf_result.pdf, filename: filename)
      else
        failure(pdf_result.error)
      end
    rescue StandardError => e
      Rails.logger.error("[InvoicePdfGenerator] Error generating PDF for Invoice ##{invoice&.id}: #{e.message}")
      failure(e.message)
    end

    def filename
      "Invoice-#{invoice.invoice_number}.pdf"
    end

    private

    def validate_invoice!
      raise ArgumentError, "Invoice is required" if invoice.blank?
      raise ArgumentError, "Invoice must be persisted" unless invoice.persisted?
    end

    def render_invoice_html
      renderer = ApplicationController.renderer.new(
        http_host: Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
      )

      renderer.render(
        template: "invoices/pdf",
        layout: "pdf",
        assigns: { invoice: invoice }
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
