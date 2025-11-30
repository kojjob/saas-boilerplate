# frozen_string_literal: true

class CreateMaterialEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :material_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.date :date, null: false
      t.string :name, null: false
      t.text :description
      t.decimal :quantity, precision: 10, scale: 2, default: 1, null: false
      t.decimal :unit_cost, precision: 10, scale: 2, null: false
      t.decimal :markup_percentage, precision: 5, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2

      t.boolean :billable, default: true, null: false
      t.boolean :invoiced, default: false, null: false

      t.timestamps
    end

    add_index :material_entries, [ :project_id, :date ]
    add_index :material_entries, :billable
    add_index :material_entries, :invoiced
  end
end
