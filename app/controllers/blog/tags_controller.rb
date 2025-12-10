# frozen_string_literal: true

module Blog
  class TagsController < ApplicationController
    skip_before_action :authenticate!, only: [:show]

    def show
      @tag = BlogTag.find_by!(slug: params[:id])
      @posts = BlogPost.published
                       .by_tag(@tag.id)
                       .includes(:author, :blog_category)
                       .recent
                       .page(params[:page])
                       .per(12)
    end
  end
end
