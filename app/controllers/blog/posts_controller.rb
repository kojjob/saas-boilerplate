# frozen_string_literal: true

module Blog
  class PostsController < ApplicationController
    skip_before_action :authenticate!, only: [:index, :show, :search]

    def index
      @posts = BlogPost.published
                       .includes(:author, :blog_category, :blog_tags)
                       .recent
                       .page(params[:page])
                       .per(12)

      @featured_posts = BlogPost.published.featured.recent.limit(3) if params[:page].blank?
      @categories = BlogCategory.with_posts.ordered
      @popular_tags = BlogTag.with_posts.popular.limit(10)
    end

    def show
      @post = BlogPost.published.find_by!(slug: params[:id])
      @post.increment_views!

      @related_posts = find_related_posts
      @previous_post = @post.previous_post
      @next_post = @post.next_post
    end

    def search
      @query = params[:q].to_s.strip
      return redirect_to posts_path if @query.blank?

      @posts = BlogPost.published
                       .search(@query)
                       .includes(:author, :blog_category)
                       .recent
                       .page(params[:page])
                       .per(12)
    end

    private

    def find_related_posts
      return BlogPost.none if @post.blog_tags.empty? && @post.blog_category.blank?

      related = BlogPost.published.where.not(id: @post.id)

      if @post.blog_tags.any?
        tag_ids = @post.blog_tags.pluck(:id)
        related = related.joins(:blog_post_tags)
                         .where(blog_post_tags: { blog_tag_id: tag_ids })
                         .or(related.where(blog_category_id: @post.blog_category_id))
      elsif @post.blog_category.present?
        related = related.where(blog_category_id: @post.blog_category_id)
      end

      related.distinct.recent.limit(3)
    end
  end
end
