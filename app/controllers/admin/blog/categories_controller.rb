# frozen_string_literal: true

module Admin
  module Blog
    class CategoriesController < Admin::BaseController
      before_action :set_category, only: [:show, :edit, :update, :destroy]

      def index
        @categories = BlogCategory.includes(:parent, :children)
                                  .order(position: :asc, name: :asc)
                                  .page(params[:page])
                                  .per(20)
      end

      def show
        @posts = @category.blog_posts.includes(:author).recent.limit(10)
      end

      def new
        @category = BlogCategory.new
        @parent_categories = BlogCategory.roots.ordered
      end

      def create
        @category = BlogCategory.new(category_params)

        if @category.save
          redirect_to admin_blog_category_path(@category), notice: "Category was successfully created."
        else
          @parent_categories = BlogCategory.roots.ordered
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @parent_categories = BlogCategory.roots.where.not(id: @category.id).ordered
      end

      def update
        if @category.update(category_params)
          redirect_to admin_blog_category_path(@category), notice: "Category was successfully updated."
        else
          @parent_categories = BlogCategory.roots.where.not(id: @category.id).ordered
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @category.blog_posts.any?
          redirect_to admin_blog_categories_path,
                      alert: "Cannot delete category with posts. Move or delete the posts first."
        else
          @category.destroy
          redirect_to admin_blog_categories_path, notice: "Category was successfully deleted."
        end
      end

      private

      def set_category
        @category = BlogCategory.find_by!(slug: params[:id])
      end

      def category_params
        params.require(:blog_category).permit(
          :name, :slug, :description,
          :meta_title, :meta_description,
          :parent_id, :position
        )
      end
    end
  end
end
