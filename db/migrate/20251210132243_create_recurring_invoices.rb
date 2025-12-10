class CreateRecurringInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :project, foreign_key: true

      # Recurring invoice details
      t.string :name, null: false
      t.integer :frequency, default: 2, null: false  # 0=weekly, 1=biweekly, 2=monthly, 3=quarterly, 4=annually
      t.integer :status, default: 0, null: false     # 0=active, 1=paused, 2=cancelled, 3=completed

      # Scheduling
      t.date :start_date, null: false
      t.date :end_date
      t.date :next_occurrence_date
      t.date :last_generated_at

      # Occurrence tracking
      t.integer :occurrences_count, default: 0, null: false
      t.integer :occurrences_limit  # nil means unlimited

      # Invoice settings
      t.integer :payment_terms, default: 30, null: false  # Days until due
      t.string :currency, default: "USD", null: false
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0
      t.text :notes

      # Auto-send settings
      t.boolean :auto_send, default: false, null: false
      t.string :email_subject
      t.text :email_body

      t.timestamps
    end

    add_index :recurring_invoices, [:account_id, :status]
    add_index :recurring_invoices, [:account_id, :next_occurrence_date]
  end
end
