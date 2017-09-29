# frozen_string_literal: true

class ArticlesController < ApplicationController
  respond_to :json
  before_action :set_course, only: [:details]

  # returns revision score data for vega graphs
  def article_data
    @article = Article.find(params[:article_id])
  end

  # returns details about how an article changed during a course
  def details
    @article = Article.find(params[:article_id])
    revisions = @course.revisions.where(article_id: @article.id).order(:date)
    @first_revision = revisions.first
    @last_revision = revisions.last
    editor_ids = revisions.pluck(:user_id).uniq
    @editors = User.where(id: editor_ids)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
