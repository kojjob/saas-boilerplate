# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain

  def about
    # Team members for the about page
    @team_members = [
      {
        name: "Marcus Johnson",
        role: "Founder & CEO",
        bio: "Former electrician turned tech entrepreneur. 15 years in the trades before building the software he wished existed.",
        image: "team/marcus.jpg",
        linkedin: "#",
        twitter: "#"
      },
      {
        name: "Sarah Chen",
        role: "Head of Product",
        bio: "Product designer who spent 5 years at a construction management startup. Obsessed with making complex tools simple.",
        image: "team/sarah.jpg",
        linkedin: "#",
        twitter: "#"
      },
      {
        name: "David Rodriguez",
        role: "Lead Engineer",
        bio: "Full-stack developer with a passion for building reliable systems. Previously at Stripe and Square.",
        image: "team/david.jpg",
        linkedin: "#",
        twitter: "#"
      },
      {
        name: "Emily Thompson",
        role: "Customer Success",
        bio: "Comes from a family of HVAC contractors. She speaks your language and has your back.",
        image: "team/emily.jpg",
        linkedin: "#",
        twitter: "#"
      }
    ]

    # Company stats
    @stats = [
      { value: "2,500+", label: "Happy Contractors", icon: "users" },
      { value: "$12M+", label: "Invoices Processed", icon: "currency" },
      { value: "99.9%", label: "Uptime", icon: "check" },
      { value: "4.9/5", label: "Customer Rating", icon: "star" }
    ]

    # Company values
    @values = [
      {
        title: "Built for the Trades",
        description: "We're not another generic invoicing app. Every feature is designed specifically for subcontractors and their unique workflows.",
        icon: "wrench"
      },
      {
        title: "Simplicity First",
        description: "Complex software doesn't make your job easier. We obsess over making every feature intuitive and fast.",
        icon: "sparkles"
      },
      {
        title: "Your Success is Ours",
        description: "When you get paid faster and run your business better, we've done our job. Your success drives everything we do.",
        icon: "trophy"
      },
      {
        title: "Always Improving",
        description: "We ship updates weekly based on real feedback from contractors like you. Your voice shapes our roadmap.",
        icon: "rocket"
      }
    ]
  end

  def contact
    @contact_reasons = [
      { value: "general", label: "General Inquiry" },
      { value: "sales", label: "Sales Question" },
      { value: "support", label: "Technical Support" },
      { value: "billing", label: "Billing Question" },
      { value: "partnership", label: "Partnership Opportunity" },
      { value: "press", label: "Press & Media" }
    ]
  end

  def send_contact
    # In a real application, you would:
    # 1. Validate the form data
    # 2. Send an email using ActionMailer
    # 3. Create a support ticket
    # 4. Log the inquiry

    name = params[:name]
    email = params[:email]
    reason = params[:reason]
    message = params[:message]

    # Basic validation
    if name.blank? || email.blank? || message.blank?
      flash.now[:alert] = "Please fill in all required fields."
      @contact_reasons = contact_reasons_list
      render :contact, status: :unprocessable_entity
      return
    end

    # Here you would send the email
    # ContactMailer.inquiry(name: name, email: email, reason: reason, message: message).deliver_later

    redirect_to contact_path, notice: "Thank you for reaching out! We'll get back to you within 24 hours."
  end

  private

  def contact_reasons_list
    [
      { value: "general", label: "General Inquiry" },
      { value: "sales", label: "Sales Question" },
      { value: "support", label: "Technical Support" },
      { value: "billing", label: "Billing Question" },
      { value: "partnership", label: "Partnership Opportunity" },
      { value: "press", label: "Press & Media" }
    ]
  end
end
