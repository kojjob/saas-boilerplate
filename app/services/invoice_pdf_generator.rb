# frozen_string_literal: true

class InvoicePdfGenerator < ApplicationService
  attr_reader :invoice

  def initialize(invoice)
    @invoice = invoice
  end

  def call
    pdf_data = generate_pdf
    success(pdf: pdf_data, filename: filename)
  rescue StandardError => e
    failure("Failed to generate PDF: #{e.message}")
  end

  def filename
    "invoice_#{invoice.invoice_number.downcase.gsub(/[^a-z0-9]/, '_')}.pdf"
  end

  private

  def generate_pdf
    Prawn::Document.new(page_size: "LETTER", margin: 50) do |pdf|
      render_header(pdf)
      render_business_info(pdf)
      render_client_info(pdf)
      render_invoice_details(pdf)
      render_line_items(pdf)
      render_totals(pdf)
      render_notes(pdf)
      render_status_badge(pdf) if invoice.paid?
      render_footer(pdf)
    end.render
  end

  def render_header(pdf)
    pdf.font_size(24) do
      pdf.text "INVOICE", style: :bold, align: :center
    end
    pdf.move_down 10
    pdf.stroke_horizontal_rule
    pdf.move_down 20
  end

  def render_business_info(pdf)
    pdf.font_size(10) do
      pdf.text invoice.account.name, style: :bold, size: 14
      if invoice.account.respond_to?(:address) && invoice.account.address.present?
        pdf.text invoice.account.address
      end
      if invoice.account.respond_to?(:phone) && invoice.account.phone.present?
        pdf.text "Phone: #{invoice.account.phone}"
      end
      if invoice.account.respond_to?(:email) && invoice.account.email.present?
        pdf.text "Email: #{invoice.account.email}"
      end
    end
    pdf.move_down 20
  end

  def render_client_info(pdf)
    pdf.text "Bill To:", style: :bold
    pdf.font_size(10) do
      pdf.text invoice.client.name
      pdf.text invoice.client.company if invoice.client.company.present?
      if invoice.client.respond_to?(:address) && invoice.client.address.present?
        pdf.text invoice.client.address
      elsif invoice.client.respond_to?(:street_address)
        address_parts = []
        address_parts << invoice.client.street_address if invoice.client.street_address.present?
        if invoice.client.respond_to?(:city) && invoice.client.city.present?
          city_line = [invoice.client.city, invoice.client.state].compact.join(", ")
          city_line += " #{invoice.client.zip_code}" if invoice.client.respond_to?(:zip_code) && invoice.client.zip_code.present?
          address_parts << city_line
        end
        address_parts.each { |part| pdf.text part }
      end
    end
    pdf.move_down 20
  end

  def render_invoice_details(pdf)
    details_data = [
      ["Invoice Number:", invoice.invoice_number],
      ["Issue Date:", format_date(invoice.issue_date)],
      ["Due Date:", format_date(invoice.due_date)]
    ]

    details_data << ["Status:", invoice.status.titleize] if invoice.paid?

    pdf.table(details_data, position: :right, width: 200) do
      cells.borders = []
      cells.padding = [2, 5]
      column(0).font_style = :bold
    end
    pdf.move_down 20
  end

  def render_line_items(pdf)
    return if invoice.line_items.empty?

    items_data = [["Description", "Quantity", "Rate", "Amount"]]

    invoice.line_items.each do |item|
      items_data << [
        item.description,
        item.quantity.to_s,
        format_currency(item.unit_price),
        format_currency(item.amount)
      ]
    end

    pdf.table(items_data, header: true, width: pdf.bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = "EEEEEE"
      cells.padding = [8, 5]
      cells.borders = [:bottom]
      column(1).align = :center
      column(2).align = :right
      column(3).align = :right
    end
    pdf.move_down 20
  end

  def render_totals(pdf)
    totals_data = []

    totals_data << ["Subtotal:", format_currency(invoice.subtotal)]

    if invoice.respond_to?(:discount_amount) && invoice.discount_amount.to_f > 0
      totals_data << ["Discount:", "-#{format_currency(invoice.discount_amount)}"]
    end

    if invoice.respond_to?(:tax_amount) && invoice.tax_amount.to_f > 0
      tax_label = "Tax"
      tax_label += " (#{invoice.tax_rate}%)" if invoice.respond_to?(:tax_rate) && invoice.tax_rate.present?
      totals_data << [tax_label + ":", format_currency(invoice.tax_amount)]
    end

    totals_data << ["Total:", format_currency(invoice.total_amount)]

    pdf.table(totals_data, position: :right, width: 200) do
      cells.borders = []
      cells.padding = [4, 5]
      column(0).font_style = :bold
      column(1).align = :right
      row(-1).font_style = :bold
      row(-1).size = 12
    end
    pdf.move_down 20
  end

  def render_notes(pdf)
    return unless invoice.notes.present?

    pdf.text "Notes:", style: :bold
    pdf.move_down 5
    pdf.font_size(10) do
      pdf.text invoice.notes
    end
    pdf.move_down 20
  end

  def render_status_badge(pdf)
    pdf.fill_color "228B22"
    pdf.font_size(16) do
      pdf.text "PAID", style: :bold, align: :center
    end
    pdf.fill_color "000000"
    pdf.move_down 10
  end

  def render_footer(pdf)
    pdf.move_down 30
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.font_size(8) do
      pdf.text "Thank you for your business!", align: :center
    end
  end

  def format_date(date)
    return "" unless date

    date.strftime("%B %d, %Y")
  end

  def format_currency(amount)
    return "$0.00" unless amount

    "$#{sprintf('%.2f', amount)}"
  end
end
