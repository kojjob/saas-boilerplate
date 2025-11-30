# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      # Project Information
      t.string :name, null: false
      t.text :description
      t.string :project_number

      # Status and dates
      t.integer :status, default: 0, null: false
      t.date :start_date
      t.date :end_date
      t.date :due_date

      # Financial
      t.decimal :budget, precision: 10, scale: 2
      t.decimal :hourly_rate, precision: 10, scale: 2

      # Address (job site)
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code

      t.text :notes

      t.timestamps
    end

    add_index :projects, [ :account_id, :project_number ], unique: true, where: "project_number IS NOT NULL"
    add_index :projects, :status
    add_index :projects, [ :account_id, :client_id ]
    add_index :projects, :due_date
  end
end
