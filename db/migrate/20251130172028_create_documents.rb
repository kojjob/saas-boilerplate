# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.string :name, null: false
      t.integer :category, default: 0, null: false
      t.text :description

      t.timestamps
    end

    add_index :documents, :category
    add_index :documents, [ :account_id, :project_id ]
  end
end
