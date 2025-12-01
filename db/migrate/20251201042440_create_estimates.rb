# frozen_string_literal: true

class CreateEstimates < ActiveRecord::Migration[8.0]
  def change
    create_table :estimates do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.references :converted_invoice, null: true, foreign_key: { to_table: :invoices }

      t.string :estimate_number, null: false
      t.date :issue_date, null: false
      t.date :valid_until, null: false
      t.integer :status, default: 0, null: false

      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, default: 0

      t.text :notes
      t.text :terms

      t.datetime :sent_at
      t.datetime :viewed_at
      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :converted_at

      t.timestamps
    end

    add_index :estimates, [:account_id, :estimate_number], unique: true
    add_index :estimates, :status
    add_index :estimates, :valid_until
  end
end
