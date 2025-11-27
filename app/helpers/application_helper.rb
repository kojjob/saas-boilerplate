module ApplicationHelper
  include Pagy::Frontend

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
end
