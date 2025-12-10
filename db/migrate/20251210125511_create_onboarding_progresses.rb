class CreateOnboardingProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_progresses do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :client_created, default: false, null: false
      t.boolean :project_created, default: false, null: false
      t.boolean :invoice_created, default: false, null: false
      t.boolean :invoice_sent, default: false, null: false
      t.boolean :dismissed, default: false, null: false
      t.datetime :client_created_at
      t.datetime :project_created_at
      t.datetime :invoice_created_at
      t.datetime :invoice_sent_at
      t.datetime :dismissed_at

      t.timestamps
    end
  end
end
