# frozen_string_literal: true

module Admin
  module Blog
    class TagsController < Admin::BaseController
      include Pagy::Backend

      before_action :set_tag, only: [:show, :edit, :update, :destroy]

      def index
        tags = BlogTag.order(name: :asc)
        @pagy, @tags = pagy(tags, limit: 20)
      end

      def show
        @posts = BlogPost.by_tag(@tag.id).includes(:author).recent.limit(10)
      end

      def new
        @tag = BlogTag.new
      end

      def create
        @tag = BlogTag.new(tag_params)

        if @tag.save
          redirect_to admin_blog_tag_path(@tag), notice: "Tag was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @tag.update(tag_params)
          redirect_to admin_blog_tag_path(@tag), notice: "Tag was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @tag.destroy
        redirect_to admin_blog_tags_path, notice: "Tag was successfully deleted."
      end

      private

      def set_tag
        @tag = BlogTag.find_by!(slug: params[:id])
      end

      def tag_params
        params.require(:blog_tag).permit(:name, :slug, :description)
      end
    end
  end
end
