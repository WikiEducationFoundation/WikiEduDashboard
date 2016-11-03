# frozen_string_literal: true
class ArticlesController < ApplicationController
  respond_to :json
  before_action :set_course, only: [:details]

  # returns revision score data for vega graphs
  def wp10
    @article = Article.find(params[:article_id])
  end

  # returns details about how an article changed during a course
  def details
    @article = Article.find(params[:article_id])
    @first_revision = @course.revisions.where(article_id: @article.id).order(:date).first
    @last_revision = @course.revisions.where(article_id: @article.id).order(:date).last
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
