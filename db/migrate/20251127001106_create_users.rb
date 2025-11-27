class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :confirmed_at
      t.string :confirmation_token
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :confirmation_token, unique: true, where: 'confirmation_token IS NOT NULL'
    add_index :users, :reset_password_token, unique: true, where: 'reset_password_token IS NOT NULL'
    add_index :users, :discarded_at
  end
end
