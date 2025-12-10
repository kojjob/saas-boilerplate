class AddMetaKeywordsToBlogPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :blog_posts, :meta_keywords, :string
  end
end
