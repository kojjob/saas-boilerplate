# frozen_string_literal: true

# Currencyable concern provides multi-currency support for models
# that need to work with monetary values in different currencies.
#
# This concern provides:
# - A list of supported currencies with symbols and names
# - Validation helper for currency attributes
# - Instance methods for formatting and displaying currency values
#
# Usage:
#   include Currencyable
#   validate_currency_attribute :currency  # for required currency field
#   validate_currency_attribute :preferred_currency, allow_nil: true  # for optional fields
#
module Currencyable
  extend ActiveSupport::Concern

  SUPPORTED_CURRENCIES = %w[
    USD EUR GBP CAD AUD JPY CHF NZD
    SEK NOK DKK SGD HKD MXN BRL INR
    ZAR PLN CZK HUF ILS AED SAR KRW
  ].freeze

  CURRENCY_SYMBOLS = {
    "USD" => "$",
    "EUR" => "€",
    "GBP" => "£",
    "CAD" => "C$",
    "AUD" => "A$",
    "JPY" => "¥",
    "CHF" => "CHF",
    "NZD" => "NZ$",
    "SEK" => "kr",
    "NOK" => "kr",
    "DKK" => "kr",
    "SGD" => "S$",
    "HKD" => "HK$",
    "MXN" => "MX$",
    "BRL" => "R$",
    "INR" => "₹",
    "ZAR" => "R",
    "PLN" => "zł",
    "CZK" => "Kč",
    "HUF" => "Ft",
    "ILS" => "₪",
    "AED" => "د.إ",
    "SAR" => "﷼",
    "KRW" => "₩"
  }.freeze

  CURRENCY_NAMES = {
    "USD" => "US Dollar",
    "EUR" => "Euro",
    "GBP" => "British Pound",
    "CAD" => "Canadian Dollar",
    "AUD" => "Australian Dollar",
    "JPY" => "Japanese Yen",
    "CHF" => "Swiss Franc",
    "NZD" => "New Zealand Dollar",
    "SEK" => "Swedish Krona",
    "NOK" => "Norwegian Krone",
    "DKK" => "Danish Krone",
    "SGD" => "Singapore Dollar",
    "HKD" => "Hong Kong Dollar",
    "MXN" => "Mexican Peso",
    "BRL" => "Brazilian Real",
    "INR" => "Indian Rupee",
    "ZAR" => "South African Rand",
    "PLN" => "Polish Zloty",
    "CZK" => "Czech Koruna",
    "HUF" => "Hungarian Forint",
    "ILS" => "Israeli Shekel",
    "AED" => "UAE Dirham",
    "SAR" => "Saudi Riyal",
    "KRW" => "South Korean Won"
  }.freeze

  included do
    # Subclasses should call validate_currency_attribute to set up validations
  end

  # Module-level method for currency_options_for_select
  # This allows calling Currencyable.currency_options_for_select directly
  def self.currency_options_for_select
    SUPPORTED_CURRENCIES.map do |code|
      symbol = CURRENCY_SYMBOLS[code] || code
      name = CURRENCY_NAMES[code] || code
      ["#{code} (#{symbol}) - #{name}", code]
    end
  end

  class_methods do
    # Returns an array suitable for use in select form helpers
    # @return [Array<Array>] Array of [display_name, currency_code] pairs
    def currency_options_for_select
      SUPPORTED_CURRENCIES.map do |code|
        symbol = CURRENCY_SYMBOLS[code] || code
        name = CURRENCY_NAMES[code] || code
        ["#{code} (#{symbol}) - #{name}", code]
      end
    end

    # Validates a currency attribute
    # @param attribute [Symbol] The attribute name to validate
    # @param allow_nil [Boolean] Whether to allow nil values (default: false)
    def validate_currency_attribute(attribute, allow_nil: false)
      validates attribute, inclusion: {
        in: SUPPORTED_CURRENCIES,
        message: "is not a supported currency"
      }, allow_nil: allow_nil
    end
  end

  # Returns the currency symbol for this record's currency
  # @return [String] The currency symbol (e.g., "$", "€", "£")
  def currency_symbol
    currency_code = respond_to?(:effective_currency) ? effective_currency : currency
    CURRENCY_SYMBOLS[currency_code] || "$"
  end

  # Returns the full name of this record's currency
  # @return [String] The currency name (e.g., "US Dollar", "Euro")
  def currency_name
    currency_code = respond_to?(:effective_currency) ? effective_currency : currency
    CURRENCY_NAMES[currency_code] || currency_code
  end

  # Formats a monetary amount with the appropriate currency symbol
  # @param amount [Numeric] The amount to format
  # @return [String] Formatted amount with currency symbol (e.g., "$1,234.56")
  def format_currency(amount)
    currency_code = respond_to?(:effective_currency) ? effective_currency : currency
    symbol = CURRENCY_SYMBOLS[currency_code] || "$"

    if amount.negative?
      "-#{symbol}#{number_with_precision(amount.abs)}"
    else
      "#{symbol}#{number_with_precision(amount)}"
    end
  end

  private

  # Helper method to format numbers with precision and thousands separator
  def number_with_precision(number)
    # Round to 2 decimal places and format with thousands separator
    formatted = format("%.2f", number.to_f)
    integer_part, decimal_part = formatted.split(".")
    integer_with_commas = integer_part.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
    "#{integer_with_commas}.#{decimal_part}"
  end
end
