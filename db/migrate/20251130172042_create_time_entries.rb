# frozen_string_literal: true

class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.date :date, null: false
      t.decimal :hours, precision: 5, scale: 2, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2

      t.text :description
      t.boolean :billable, default: true, null: false
      t.boolean :invoiced, default: false, null: false

      t.timestamps
    end

    add_index :time_entries, [ :project_id, :date ]
    add_index :time_entries, [ :user_id, :date ]
    add_index :time_entries, :billable
    add_index :time_entries, :invoiced
  end
end
