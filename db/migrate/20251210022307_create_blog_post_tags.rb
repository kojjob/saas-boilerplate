class CreateBlogPostTags < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_post_tags, id: :uuid do |t|
      t.references :blog_post, null: false, foreign_key: true, type: :uuid
      t.references :blog_tag, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :blog_post_tags, [:blog_post_id, :blog_tag_id], unique: true
  end
end
