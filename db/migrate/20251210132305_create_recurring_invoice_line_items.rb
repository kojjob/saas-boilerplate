class CreateRecurringInvoiceLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_invoice_line_items do |t|
      t.references :recurring_invoice, null: false, foreign_key: true

      # Line item details
      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false

      # Ordering
      t.integer :position

      t.timestamps
    end

    add_index :recurring_invoice_line_items, [:recurring_invoice_id, :position], name: "idx_recurring_line_items_position"
  end
end
