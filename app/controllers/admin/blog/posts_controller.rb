# frozen_string_literal: true

module Admin
  module Blog
    class PostsController < Admin::BaseController
      before_action :set_post, only: [:show, :edit, :update, :destroy]
      before_action :load_form_resources, only: [:new, :edit, :create, :update]

      def index
        @posts = BlogPost.includes(:author, :blog_category, :blog_tags)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(20)

        filter_posts if params[:status].present? || params[:category].present?
      end

      def show; end

      def new
        @post = BlogPost.new
      end

      def create
        @post = BlogPost.new(post_params)
        @post.author = current_user

        if @post.save
          sync_tags
          redirect_to admin_blog_post_path(@post), notice: "Post was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @post.update(post_params)
          sync_tags
          redirect_to admin_blog_post_path(@post), notice: "Post was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @post.destroy
        redirect_to admin_blog_posts_path, notice: "Post was successfully deleted."
      end

      private

      def set_post
        @post = BlogPost.find_by!(slug: params[:id])
      end

      def load_form_resources
        @categories = BlogCategory.ordered
        @tags = BlogTag.alphabetical
      end

      def post_params
        params.require(:blog_post).permit(
          :title, :slug, :content, :excerpt,
          :meta_title, :meta_description,
          :featured_image_url, :blog_category_id,
          :status, :published_at, :featured, :allow_comments
        )
      end

      def sync_tags
        return unless params[:blog_post][:tag_ids].present?

        tag_ids = params[:blog_post][:tag_ids].reject(&:blank?)
        @post.blog_tag_ids = tag_ids
      end

      def filter_posts
        @posts = @posts.where(status: params[:status]) if params[:status].present?
        @posts = @posts.where(blog_category_id: params[:category]) if params[:category].present?
      end
    end
  end
end
