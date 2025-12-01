# frozen_string_literal: true

class CreateEstimateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_line_items do |t|
      t.references :estimate, null: false, foreign_key: true

      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :estimate_line_items, [:estimate_id, :position]
  end
end
