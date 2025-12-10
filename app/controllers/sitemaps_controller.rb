# frozen_string_literal: true

class SitemapsController < ApplicationController
  skip_before_action :authenticate!

  def index
    @posts = BlogPost.published.recent
    @categories = BlogCategory.with_posts
    @tags = BlogTag.with_posts

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
