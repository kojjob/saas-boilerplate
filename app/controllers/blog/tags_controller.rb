# frozen_string_literal: true

module Blog
  class TagsController < ApplicationController
    include Pagy::Backend

    # Public blog tags - no authentication required

    def show
      @tag = BlogTag.find_by!(slug: params[:id])
      posts = BlogPost.published
                      .by_tag(@tag.id)
                      .includes(:author, :blog_category)
                      .recent
      @pagy, @posts = pagy(posts, limit: 12)
    end
  end
end
