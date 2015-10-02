class ArticlesController < ApplicationController
  def show
    @article = Article.paginate(:page => params[:page]).joins(:comments).find_by_id(params["format"])
  end
end
