# frozen_string_literal: true

class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :account, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :client, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, default: "USD"
      t.integer :category, default: 0, null: false
      t.date :expense_date, null: false
      t.string :vendor
      t.boolean :billable, default: false
      t.boolean :reimbursable, default: false
      t.text :notes

      t.timestamps
    end

    add_index :expenses, :expense_date
    add_index :expenses, :category
    add_index :expenses, :billable
    add_index :expenses, :reimbursable
    add_index :expenses, [:account_id, :expense_date]
  end
end
