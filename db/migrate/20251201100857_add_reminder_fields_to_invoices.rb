class AddReminderFieldsToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :reminder_sent_at, :datetime
    add_column :invoices, :reminder_count, :integer, default: 0, null: false
  end
end
