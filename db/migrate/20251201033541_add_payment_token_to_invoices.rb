class AddPaymentTokenToInvoices < ActiveRecord::Migration[8.1]
  def up
    add_column :invoices, :payment_token, :string

    # Populate existing invoices with payment tokens using Ruby
    Invoice.reset_column_information
    Invoice.where(payment_token: nil).find_each do |invoice|
      invoice.update_column(:payment_token, SecureRandom.hex(16))
    end

    change_column_null :invoices, :payment_token, false
    add_index :invoices, :payment_token, unique: true
  end

  def down
    remove_index :invoices, :payment_token
    remove_column :invoices, :payment_token
  end
end
