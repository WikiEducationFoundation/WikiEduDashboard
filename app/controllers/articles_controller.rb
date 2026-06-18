# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/revision_score_manager"

class ArticlesController < ApplicationController
  respond_to :json
  before_action :set_course, except: :revision_score

  # Scores the given revisions for the article development graphs. The frontend
  # fetches the revision list itself (client-side, from the MediaWiki API) and
  # POSTs the ids here for wp10 scoring.
  #   params: { rev_ids: [123, 456] }  ->  { "123": 0.5, "456": null }
  def revision_score
    @article = Article.find(params[:article_id])
    rev_manager = RevisionScoreManager.new(@article)
    render json: rev_manager.scores_for(params[:rev_ids]), root: false
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
