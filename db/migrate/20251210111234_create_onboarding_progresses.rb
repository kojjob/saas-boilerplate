class CreateOnboardingProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_progresses do |t|
      t.references :user, index: { unique: true }, null: false, foreign_key: true
      t.datetime :created_client_at
      t.datetime :created_project_at
      t.datetime :created_invoice_at
      t.datetime :sent_invoice_at
      t.datetime :dismissed_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
