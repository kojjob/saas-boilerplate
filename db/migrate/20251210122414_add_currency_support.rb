# frozen_string_literal: true

class AddCurrencySupport < ActiveRecord::Migration[8.1]
  def change
    # Add currency column to invoices (required, defaults to USD)
    add_column :invoices, :currency, :string, default: "USD", null: false

    # Add default_currency to accounts (defaults to USD)
    add_column :accounts, :default_currency, :string, default: "USD"

    # Add preferred_currency to clients (optional, can be nil to inherit from account)
    add_column :clients, :preferred_currency, :string

    # Add index for potential filtering by currency
    add_index :invoices, :currency
    add_index :accounts, :default_currency
  end
end
