class CreateBlogCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_categories, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :meta_title
      t.text :meta_description
      t.uuid :parent_id
      t.integer :position, default: 0
      t.integer :posts_count, default: 0

      t.timestamps
    end

    add_index :blog_categories, :slug, unique: true
    add_index :blog_categories, :parent_id
    add_index :blog_categories, :position
    add_foreign_key :blog_categories, :blog_categories, column: :parent_id
  end
end
