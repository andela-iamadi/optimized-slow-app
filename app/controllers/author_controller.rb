class AuthorController < ApplicationController
  def index
    @authors = Author.paginate(:page => params[:page]).includes(:articles)
  end
end
