module ApplicationHelper
  include Pagy::Frontend

  # Sidebar navigation link helper
  def sidebar_link_to(name, path, icon: nil, badge: nil)
    is_active = current_page?(path)

    link_classes = if is_active
      "group flex items-center px-3 py-2.5 text-sm font-medium rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-lg shadow-amber-500/25 transition-all duration-200"
    else
      "group flex items-center px-3 py-2.5 text-sm font-medium rounded-xl text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all duration-200"
    end

    link_to path, class: link_classes do
      concat(sidebar_icon(icon, is_active)) if icon.present?
      concat(content_tag(:span, name, class: "ml-3"))
      concat(content_tag(:span, badge, class: "ml-auto bg-amber-500 text-white text-xs px-2 py-0.5 rounded-full")) if badge.present?
    end
  end


  def render_subscription_badge(status)
    status = status.to_s

    badge_classes = case status
    when "trialing"
      "bg-blue-100 text-blue-800"
    when "active"
      "bg-green-100 text-green-800"
    when "past_due"
      "bg-amber-100 text-amber-800"
    when "canceled"
      "bg-red-100 text-red-800"
    when "paused"
      "bg-slate-100 text-slate-800"
    else
      "bg-slate-100 text-slate-800"
    end

    content_tag(:span, status.titleize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{badge_classes}")
  end

  # Project status badge styling
  def project_status_class(status)
    case status.to_s
    when "draft"
      "bg-slate-100 text-slate-800"
    when "active", "in_progress"
      "bg-blue-100 text-blue-800"
    when "on_hold"
      "bg-amber-100 text-amber-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "cancelled", "canceled"
      "bg-red-100 text-red-800"
    when "archived"
      "bg-slate-100 text-slate-600"
    else
      "bg-slate-100 text-slate-800"
    end
  end

  # Invoice status badge styling
  def invoice_status_class(status)
    case status.to_s
    when "draft"
      "bg-slate-100 text-slate-800"
    when "sent", "pending"
      "bg-blue-100 text-blue-800"
    when "viewed"
      "bg-purple-100 text-purple-800"
    when "paid"
      "bg-green-100 text-green-800"
    when "partial"
      "bg-amber-100 text-amber-800"
    when "overdue"
      "bg-red-100 text-red-800"
    when "cancelled", "canceled"
      "bg-slate-100 text-slate-600"
    else
      "bg-slate-100 text-slate-800"
    end
  end

  # Invoice status icon background color
  def invoice_status_bg_class(status)
    case status.to_s
    when "draft"
      "bg-slate-100"
    when "sent", "pending"
      "bg-blue-100"
    when "viewed"
      "bg-purple-100"
    when "paid"
      "bg-green-100"
    when "partial"
      "bg-amber-100"
    when "overdue"
      "bg-red-100"
    when "cancelled", "canceled"
      "bg-slate-100"
    else
      "bg-slate-100"
    end
  end

  # Invoice status icon color
  def invoice_status_icon_class(status)
    case status.to_s
    when "draft"
      "text-slate-600"
    when "sent", "pending"
      "text-blue-600"
    when "viewed"
      "text-purple-600"
    when "paid"
      "text-green-600"
    when "partial"
      "text-amber-600"
    when "overdue"
      "text-red-600"
    when "cancelled", "canceled"
      "text-slate-500"
    else
      "text-slate-600"
    end
  end

  # Client status badge styling
  def client_status_class(status)
    case status.to_s
    when "active"
      "bg-green-100 text-green-800"
    when "archived"
      "bg-slate-100 text-slate-600"
    else
      "bg-slate-100 text-slate-800"
    end
  end

  # Generic status badge class (for recurring invoices and other entities)
  def status_badge_class(status)
    case status.to_s
    when "active"
      "bg-green-100 text-green-800"
    when "paused"
      "bg-amber-100 text-amber-800"
    when "cancelled", "canceled"
      "bg-red-100 text-red-800"
    when "completed"
      "bg-blue-100 text-blue-800"
    when "draft"
      "bg-slate-100 text-slate-800"
    when "sent", "pending"
      "bg-blue-100 text-blue-800"
    when "paid"
      "bg-green-100 text-green-800"
    when "overdue"
      "bg-red-100 text-red-800"
    else
      "bg-slate-100 text-slate-800"
    end
  end

  # Currency options for select fields
  def currency_options
    [
      ["USD - US Dollar", "USD"],
      ["EUR - Euro", "EUR"],
      ["GBP - British Pound", "GBP"],
      ["CAD - Canadian Dollar", "CAD"],
      ["AUD - Australian Dollar", "AUD"],
      ["JPY - Japanese Yen", "JPY"],
      ["CHF - Swiss Franc", "CHF"],
      ["CNY - Chinese Yuan", "CNY"],
      ["INR - Indian Rupee", "INR"],
      ["MXN - Mexican Peso", "MXN"],
      ["BRL - Brazilian Real", "BRL"],
      ["SGD - Singapore Dollar", "SGD"],
      ["NZD - New Zealand Dollar", "NZD"],
      ["HKD - Hong Kong Dollar", "HKD"],
      ["SEK - Swedish Krona", "SEK"],
      ["NOK - Norwegian Krone", "NOK"],
      ["DKK - Danish Krone", "DKK"],
      ["ZAR - South African Rand", "ZAR"],
      ["KRW - South Korean Won", "KRW"],
      ["PLN - Polish Zloty", "PLN"]
    ]
  end

  # Currency symbol for display
  def currency_symbol(currency_code)
    symbols = {
      "USD" => "$",
      "EUR" => "€",
      "GBP" => "£",
      "CAD" => "CA$",
      "AUD" => "A$",
      "JPY" => "¥",
      "CHF" => "CHF",
      "CNY" => "¥",
      "INR" => "₹",
      "MXN" => "MX$",
      "BRL" => "R$",
      "SGD" => "S$",
      "NZD" => "NZ$",
      "HKD" => "HK$",
      "SEK" => "kr",
      "NOK" => "kr",
      "DKK" => "kr",
      "ZAR" => "R",
      "KRW" => "₩",
      "PLN" => "zł"
    }
    symbols[currency_code.to_s.upcase] || currency_code.to_s.upcase
  end

  # Sidebar icon SVG helper
  def sidebar_icon(icon_name, is_active = false)
    icon_class = is_active ? "w-5 h-5 text-white" : "w-5 h-5 text-slate-400 group-hover:text-white"

    icons = {
      "home" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />',
      "folder" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />',
      "document-text" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />',
      "users" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />',
      "document-duplicate" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />',
      "clock" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />',
      "cube" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />',
      "chat-alt-2" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />',
      "cog" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />',
      "user-group" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />',
      "credit-card" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />',
      "chart-bar" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />',
      "chart-pie" => '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />'
    }

    svg_content = icons[icon_name] || icons["home"]
    content_tag(:svg, svg_content.html_safe, class: icon_class, fill: "none", stroke: "currentColor", viewBox: "0 0 24 24")
  end
end
