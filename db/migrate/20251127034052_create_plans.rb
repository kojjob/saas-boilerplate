class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :stripe_price_id, null: false
      t.string :stripe_product_id
      t.integer :price_cents, default: 0, null: false
      t.string :interval, default: 'month', null: false
      t.integer :trial_days, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.jsonb :features, default: []
      t.jsonb :limits, default: {}
      t.text :description
      t.integer :sort_order, default: 0

      t.timestamps
    end
    add_index :plans, :stripe_price_id, unique: true
    add_index :plans, :active
    add_index :plans, :sort_order
  end
end
