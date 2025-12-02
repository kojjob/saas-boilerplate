class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :job_title, :string
    add_column :users, :time_zone, :string, default: "UTC"
    add_column :users, :locale, :string, default: "en"
    add_column :users, :email_notifications, :boolean, default: true, null: false
    add_column :users, :sms_notifications, :boolean, default: false, null: false
    add_column :users, :otp_secret, :string
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false

    add_index :users, :phone_number
  end
end
