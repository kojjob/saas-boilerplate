# frozen_string_literal: true

class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true
      t.references :alertable, polymorphic: true, type: :uuid, null: true
      t.string :alert_type, null: false
      t.integer :severity, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :title, null: false
      t.text :message
      t.jsonb :metadata, default: {}
      t.datetime :sent_at
      t.datetime :acknowledged_at
      t.string :error_message

      t.timestamps
    end

    add_index :alerts, :alert_type
    add_index :alerts, :severity
    add_index :alerts, :status
    add_index :alerts, :created_at
    add_index :alerts, [:account_id, :status]
    add_index :alerts, [:account_id, :alert_type]
  end
end
