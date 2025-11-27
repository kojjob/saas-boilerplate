class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :subdomain
      t.jsonb :settings, default: {}
      t.string :subscription_status, default: 'trialing'
      t.datetime :trial_ends_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :accounts, :slug, unique: true
    add_index :accounts, :subdomain, unique: true, where: 'subdomain IS NOT NULL'
    add_index :accounts, :discarded_at
    add_index :accounts, :subscription_status
  end
end
