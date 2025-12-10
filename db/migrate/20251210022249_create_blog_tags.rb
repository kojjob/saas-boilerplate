class CreateBlogTags < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_tags, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :posts_count, default: 0

      t.timestamps
    end

    add_index :blog_tags, :slug, unique: true
    add_index :blog_tags, :name
  end
end
