# frozen_string_literal: true

class ArticlesController < ApplicationController
  respond_to :json
  before_action :set_course, except: :article_data

  # returns revision score data for vega graphs
  def article_data
    @article = Article.find(params[:article_id])
  end

  # returns details about how an article changed during a course
  def details
    @article = Article.find(params[:article_id])
    revisions = @course.tracked_revisions.where(article_id: @article.id).order(:date)
    @first_revision = revisions.first
    @last_revision = revisions.last
    article_course = ArticlesCourses.find_by(course: @course, article: @article, tracked: true)
    @editors = User.where(id: article_course&.user_ids)
  end

  # updates the tracked status of an article
  def update_tracked_status
    article_course = @course.articles_courses.find_by(article_id: params[:article_id])
    article_course.update(tracked: params[:tracked])
    render json: {}, status: :ok
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
