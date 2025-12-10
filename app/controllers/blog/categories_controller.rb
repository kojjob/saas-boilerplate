# frozen_string_literal: true

module Blog
  class CategoriesController < ApplicationController
    include Pagy::Backend

    # Public blog categories - no authentication required

    def index
      @categories = BlogCategory.with_posts.ordered.includes(:children)
    end

    def show
      @category = BlogCategory.find_by!(slug: params[:id])
      posts = BlogPost.published
                      .by_category(@category.id)
                      .includes(:author, :blog_tags)
                      .recent
      @pagy, @posts = pagy(posts, limit: 12)

      @subcategories = @category.children.with_posts.ordered if @category.has_children?
    end
  end
end
