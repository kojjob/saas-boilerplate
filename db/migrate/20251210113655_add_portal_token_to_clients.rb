class AddPortalTokenToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :portal_token, :string
    add_index :clients, :portal_token, unique: true
    add_column :clients, :portal_token_generated_at, :datetime
    add_column :clients, :portal_enabled, :boolean, default: true, null: false
  end
end
