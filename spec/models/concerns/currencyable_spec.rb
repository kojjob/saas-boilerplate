# frozen_string_literal: true

require "rails_helper"

RSpec.describe Currencyable do
  describe "SUPPORTED_CURRENCIES" do
    it "includes common currencies" do
      expect(Currencyable::SUPPORTED_CURRENCIES).to include("USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF")
    end

    it "is frozen to prevent modification" do
      expect(Currencyable::SUPPORTED_CURRENCIES).to be_frozen
    end
  end

  describe "CURRENCY_SYMBOLS" do
    it "maps currency codes to symbols" do
      expect(Currencyable::CURRENCY_SYMBOLS["USD"]).to eq("$")
      expect(Currencyable::CURRENCY_SYMBOLS["EUR"]).to eq("€")
      expect(Currencyable::CURRENCY_SYMBOLS["GBP"]).to eq("£")
      expect(Currencyable::CURRENCY_SYMBOLS["JPY"]).to eq("¥")
    end

    it "is frozen to prevent modification" do
      expect(Currencyable::CURRENCY_SYMBOLS).to be_frozen
    end
  end

  describe "CURRENCY_NAMES" do
    it "maps currency codes to full names" do
      expect(Currencyable::CURRENCY_NAMES["USD"]).to eq("US Dollar")
      expect(Currencyable::CURRENCY_NAMES["EUR"]).to eq("Euro")
      expect(Currencyable::CURRENCY_NAMES["GBP"]).to eq("British Pound")
    end

    it "is frozen to prevent modification" do
      expect(Currencyable::CURRENCY_NAMES).to be_frozen
    end
  end

  describe ".currency_options_for_select" do
    it "returns array suitable for select options" do
      options = Currencyable.currency_options_for_select
      expect(options).to be_an(Array)
      expect(options.first).to be_an(Array)
      expect(options.first.length).to eq(2)
    end

    it "includes currency code and display name with symbol" do
      options = Currencyable.currency_options_for_select
      usd_option = options.find { |opt| opt[1] == "USD" }
      expect(usd_option[0]).to include("USD")
      expect(usd_option[0]).to include("$")
    end
  end

  describe "instance methods" do
    let(:test_class) do
      Class.new do
        include Currencyable

        attr_accessor :currency

        def initialize(currency = "USD")
          @currency = currency
        end
      end
    end

    describe "#currency_symbol" do
      it "returns the symbol for the currency" do
        instance = test_class.new("USD")
        expect(instance.currency_symbol).to eq("$")
      end

      it "returns $ for unknown currencies" do
        instance = test_class.new("XYZ")
        expect(instance.currency_symbol).to eq("$")
      end
    end

    describe "#currency_name" do
      it "returns the full name for the currency" do
        instance = test_class.new("EUR")
        expect(instance.currency_name).to eq("Euro")
      end

      it "returns the code for unknown currencies" do
        instance = test_class.new("XYZ")
        expect(instance.currency_name).to eq("XYZ")
      end
    end

    describe "#format_currency" do
      it "formats amount with currency symbol" do
        instance = test_class.new("USD")
        expect(instance.format_currency(1234.56)).to eq("$1,234.56")
      end

      it "handles different currencies" do
        instance = test_class.new("EUR")
        expect(instance.format_currency(1000)).to eq("€1,000.00")
      end

      it "handles negative amounts" do
        instance = test_class.new("USD")
        expect(instance.format_currency(-500)).to eq("-$500.00")
      end

      it "handles zero" do
        instance = test_class.new("GBP")
        expect(instance.format_currency(0)).to eq("£0.00")
      end
    end
  end
end
