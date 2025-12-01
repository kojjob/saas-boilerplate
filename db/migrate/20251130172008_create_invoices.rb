# frozen_string_literal: true

class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :project, foreign_key: true # Optional

      # Invoice Information
      t.string :invoice_number, null: false
      t.integer :status, default: 0, null: false

      # Dates
      t.date :issue_date, null: false
      t.date :due_date, null: false
      t.datetime :sent_at
      t.datetime :paid_at

      # Amounts
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, default: 0

      # Payment info
      t.string :payment_method
      t.string :payment_reference
      t.text :payment_notes

      # Additional
      t.text :notes
      t.text :terms

      t.timestamps
    end

    add_index :invoices, [ :account_id, :invoice_number ], unique: true
    add_index :invoices, :status
    add_index :invoices, :due_date
    add_index :invoices, :issue_date

    # Invoice Line Items
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true

      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :invoice_line_items, [ :invoice_id, :position ]
  end
end
