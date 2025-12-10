class AddRecurringInvoiceToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_reference :invoices, :recurring_invoice, null: true, foreign_key: true
  end
end
