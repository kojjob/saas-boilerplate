class CreateBlogPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_posts, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :content
      t.string :meta_title
      t.text :meta_description
      t.string :featured_image_url
      t.references :author, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.references :blog_category, foreign_key: true, type: :uuid
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.integer :reading_time, default: 0
      t.integer :views_count, default: 0
      t.boolean :featured, default: false
      t.boolean :allow_comments, default: true

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :status
    add_index :blog_posts, :published_at
    add_index :blog_posts, :featured
    add_index :blog_posts, [:status, :published_at]
    add_index :blog_posts, [:blog_category_id, :status]
  end
end
