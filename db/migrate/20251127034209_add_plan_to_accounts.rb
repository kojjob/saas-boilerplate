class AddPlanToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_reference :accounts, :plan, null: true, foreign_key: true
  end
end
