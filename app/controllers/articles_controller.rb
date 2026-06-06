# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/revision_score_manager"

class ArticlesController < ApplicationController
  respond_to :json
  before_action :set_course

  # Returns revision data for the article development graphs: every revision in
  # the course period (capped), scored with wp10. The frontend tags each
  # revision's editor role using the course users it already has in its store.
  #  { rev_id: 123, characters: 1000, wp10: 0.5, date: '...', username: 'X' }
  def revision_score
    @article = Article.find(params[:article_id])
    rev_manager = RevisionScoreManager.new(@article, @course)
    render json: rev_manager.fetch_scored_revisions, root: false
  end

  # returns details about how an article changed during a course
  def details
    @article = Article.find(params[:article_id])
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
