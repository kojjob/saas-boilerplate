# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe "default settings" do
    it "has correct default from email constant" do
      expect(ApplicationMailer::DEFAULT_FROM_EMAIL).to eq("noreply@example.com")
    end

    it "has correct default from name constant" do
      expect(ApplicationMailer::DEFAULT_FROM_NAME).to eq("SaaS Boilerplate")
    end

    it "uses the mailer layout" do
      expect(ApplicationMailer._layout).to eq("mailer")
    end
  end

  describe "helper methods availability" do
    it "includes EmailHelper as a helper module" do
      expect(ApplicationMailer._helpers.included_modules).to include(EmailHelper)
    end

    it "has email_button defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:email_button)
    end

    it "has email_text_link defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:email_text_link)
    end

    it "has email_heading defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:email_heading)
    end

    it "has email_paragraph defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:email_paragraph)
    end

    it "has support_email defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:support_email)
    end

    it "has company_name defined as helper_method" do
      expect(ApplicationMailer._helper_methods).to include(:company_name)
    end
  end

  describe "private helper methods" do
    let(:mailer) { ApplicationMailer.new }

    it "responds to email_button" do
      expect(mailer.respond_to?(:email_button, true)).to be true
    end

    it "responds to support_email" do
      expect(mailer.respond_to?(:support_email, true)).to be true
    end

    it "responds to company_name" do
      expect(mailer.respond_to?(:company_name, true)).to be true
    end
  end
end
