class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, foreign_key: true # nullable for pending invitations
      t.references :account, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'
      t.string :invitation_token
      t.string :invitation_email
      t.datetime :invited_at
      t.datetime :accepted_at
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :memberships, :invitation_token, unique: true, where: 'invitation_token IS NOT NULL'
    add_index :memberships, [ :user_id, :account_id ], unique: true, where: 'user_id IS NOT NULL'
    add_index :memberships, :role
  end
end
