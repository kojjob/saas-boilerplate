# frozen_string_literal: true

module InvoicesHelper
  include ActionView::Helpers::NumberHelper

  def invoice_status_badge(invoice)
    status = invoice.status.to_sym
    color_class = status_color_class(status)

    content_tag(:span, status.to_s.titleize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{color_class}")
  end

  def status_color_class(status)
    case status
    when :draft then "bg-gray-100 text-gray-800"
    when :sent then "bg-blue-100 text-blue-800"
    when :viewed then "bg-indigo-100 text-indigo-800"
    when :paid then "bg-green-100 text-green-800"
    when :overdue then "bg-red-100 text-red-800"
    when :cancelled then "bg-gray-100 text-gray-600"
    else "bg-gray-100 text-gray-800"
    end
  end

  def format_invoice_amount(amount)
    number_to_currency(amount || 0)
  end
end
