# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :account, null: false, foreign_key: true

      # Contact Information
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company

      # Address
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country

      # Status and metadata
      t.integer :status, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :clients, [ :account_id, :email ], unique: true
    add_index :clients, :status
    add_index :clients, [ :account_id, :name ]
  end
end
