# frozen_string_literal: true

module Admin
  module Blog
    class PostsController < Admin::BaseController
      include Pagy::Backend

      before_action :set_post, only: [:show, :edit, :update, :destroy, :purge_attachment]
      before_action :load_form_resources, only: [:new, :edit, :create, :update]

      def index
        posts = BlogPost.includes(:author, :blog_category, :blog_tags)
                        .order(created_at: :desc)

        posts = filter_posts(posts) if params[:status].present? || params[:category].present?
        @pagy, @posts = pagy(posts, limit: 20)
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

      def purge_attachment
        attachment = ActiveStorage::Attachment.find(params[:attachment_id])

        if attachment.record == @post
          attachment.purge_later
          respond_to do |format|
            format.html { redirect_to edit_admin_blog_post_path(@post), notice: "Attachment removed." }
            format.turbo_stream { render turbo_stream: turbo_stream.remove("attachment_#{attachment.id}") }
          end
        else
          redirect_to edit_admin_blog_post_path(@post), alert: "Unable to remove attachment."
        end
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
          :meta_title, :meta_description, :meta_keywords,
          :featured_image_url, :blog_category_id,
          :status, :published_at, :featured, :allow_comments,
          :featured_image, images: [], videos: [], audio_files: [], documents: []
        )
      end

      def sync_tags
        return unless params[:blog_post][:tag_ids].present?

        tag_ids = params[:blog_post][:tag_ids].reject(&:blank?)
        @post.blog_tag_ids = tag_ids
      end

      def filter_posts(posts)
        posts = posts.where(status: params[:status]) if params[:status].present?
        posts = posts.where(blog_category_id: params[:category]) if params[:category].present?
        posts
      end
    end
  end
end
