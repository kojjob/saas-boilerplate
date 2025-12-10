# frozen_string_literal: true

module Blog
  class CategoriesController < ApplicationController
    skip_before_action :authenticate!, only: [:index, :show]

    def index
      @categories = BlogCategory.with_posts.ordered.includes(:children)
    end

    def show
      @category = BlogCategory.find_by!(slug: params[:id])
      @posts = BlogPost.published
                       .by_category(@category.id)
                       .includes(:author, :blog_tags)
                       .recent
                       .page(params[:page])
                       .per(12)

      @subcategories = @category.children.with_posts.ordered if @category.has_children?
    end
  end
end
