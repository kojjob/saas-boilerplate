# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailHelper, type: :helper do
  describe "#email_button" do
    it "generates a button with proper styling" do
      button = helper.email_button("Click Me", "https://example.com")

      expect(button).to include("Click Me")
      expect(button).to include('href="https://example.com"')
      expect(button).to include("background:")
      expect(button).to include("border-radius")
    end

    it "allows custom colors" do
      button = helper.email_button("Click Me", "https://example.com", color: "#FF0000")

      expect(button).to include("#FF0000")
    end
  end

  describe "#email_text_link" do
    it "generates a simple text link" do
      link = helper.email_text_link("Click here", "https://example.com")

      expect(link).to include("Click here")
      expect(link).to include('href="https://example.com"')
    end
  end

  describe "#email_heading" do
    it "generates a heading with proper styling" do
      heading = helper.email_heading("Welcome!")

      expect(heading).to include("Welcome!")
      expect(heading).to include("font-size")
    end

    it "supports different levels" do
      h1 = helper.email_heading("H1", level: 1)
      h2 = helper.email_heading("H2", level: 2)

      expect(h1).to include("<h1")
      expect(h2).to include("<h2")
    end
  end

  describe "#email_paragraph" do
    it "generates a paragraph with proper styling" do
      paragraph = helper.email_paragraph("Some text content")

      expect(paragraph).to include("Some text content")
      expect(paragraph).to include("<p")
      expect(paragraph).to include("line-height")
    end
  end

  describe "#email_divider" do
    it "generates a horizontal divider" do
      divider = helper.email_divider

      expect(divider).to include("<hr")
      expect(divider).to include("border")
    end
  end

  describe "#email_spacer" do
    it "generates a spacer with default height" do
      spacer = helper.email_spacer

      expect(spacer).to include("height")
    end

    it "allows custom height" do
      spacer = helper.email_spacer(height: "40px")

      expect(spacer).to include("40px")
    end
  end

  describe "#app_logo_url" do
    it "returns a logo URL" do
      url = helper.app_logo_url

      expect(url).to be_present
    end
  end

  describe "#support_email" do
    it "returns a support email address" do
      email = helper.support_email

      expect(email).to include("@")
    end
  end

  describe "#company_name" do
    it "returns the company name" do
      name = helper.company_name

      expect(name).to be_present
    end
  end
end
