class ArticlesController < ApplicationController
  respond_to :json

  # returns revision score data for vega graphs
  def wp10
    @article = Article.find(params[:article_id])
  end
end
