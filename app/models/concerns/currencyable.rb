# frozen_string_literal: true

module Currencyable
  extend ActiveSupport::Concern

  SUPPORTED_CURRENCIES = {
    "USD" => { symbol: "$", name: "US Dollar" },
    "EUR" => { symbol: "€", name: "Euro" },
    "GBP" => { symbol: "£", name: "British Pound" },
    "CAD" => { symbol: "C$", name: "Canadian Dollar" },
    "AUD" => { symbol: "A$", name: "Australian Dollar" },
    "JPY" => { symbol: "¥", name: "Japanese Yen" },
    "CHF" => { symbol: "Fr", name: "Swiss Franc" },
    "CNY" => { symbol: "¥", name: "Chinese Yuan" },
    "INR" => { symbol: "₹", name: "Indian Rupee" },
    "MXN" => { symbol: "Mex$", name: "Mexican Peso" },
    "BRL" => { symbol: "R$", name: "Brazilian Real" },
    "KRW" => { symbol: "₩", name: "South Korean Won" },
    "SGD" => { symbol: "S$", name: "Singapore Dollar" },
    "HKD" => { symbol: "HK$", name: "Hong Kong Dollar" },
    "NOK" => { symbol: "kr", name: "Norwegian Krone" },
    "SEK" => { symbol: "kr", name: "Swedish Krona" },
    "DKK" => { symbol: "kr", name: "Danish Krone" },
    "NZD" => { symbol: "NZ$", name: "New Zealand Dollar" },
    "ZAR" => { symbol: "R", name: "South African Rand" },
    "RUB" => { symbol: "₽", name: "Russian Ruble" },
    "TRY" => { symbol: "₺", name: "Turkish Lira" },
    "PLN" => { symbol: "zł", name: "Polish Zloty" },
    "THB" => { symbol: "฿", name: "Thai Baht" },
    "IDR" => { symbol: "Rp", name: "Indonesian Rupiah" }
  }.freeze

  included do
    validates :currency, inclusion: {
      in: SUPPORTED_CURRENCIES.keys,
      message: "is not a supported currency"
    }, allow_blank: true
  end

  def currency_symbol
    SUPPORTED_CURRENCIES.dig(currency, :symbol) || "$"
  end

  def currency_name
    SUPPORTED_CURRENCIES.dig(currency, :name) || "US Dollar"
  end

  class_methods do
    def supported_currencies
      SUPPORTED_CURRENCIES
    end

    def currency_options_for_select
      SUPPORTED_CURRENCIES.map { |code, data| ["#{data[:symbol]} - #{data[:name]} (#{code})", code] }
    end
  end
end
