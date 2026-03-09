# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/lift_wing_api"

class ArticlesController < ApplicationController
  respond_to :json
  # the revision_score action derives its course from the article itself,
  # so it can't rely on a :course_id parameter.  skip the before_action
  # here to avoid a RecordNotFound/404 when course_id is missing.
  before_action :set_course, except: [:article_data, :revision_score]

  # returns revision score data for vega graphs
  def revision_score
    @article = Article.find(params[:article_id])
    @course = @article.courses.current.first
    start_date = @course.start
    end_date = @course.end + 1.week

    revisions = get_revision_ids(@article.mw_page_id, start_date, end_date)
    rev_ids = revisions.map { |r| r[:revid] }
    scores  = score_revisions(rev_ids, @article.wiki)
    
    render json: revisions.map { |rev|
      { rev_id: rev[:revid],
        characters: rev[:size],
        wp10: scores[rev[:revid].to_s]['wp10'],
        date:   rev[:timestamp],
        username:   rev[:user] 
      }
    }
    
  end

  def get_revision_ids(page_id, start_date, end_date)
    params = { action: 'query', prop: 'revisions',
               pageids: page_id,
               rvprop: 'user|ids|timestamp|size',
               rvlimit: 500 }
    params[:rvstart] = end_date.strftime('%Y%m%d%H%M%S')
    params[:rvend] = start_date.strftime('%Y%m%d%H%M%S')

    revisions = []
    lambda do 
      @wiki = Wiki.find_by(language: @article.wiki.language, project: @article.wiki.project)
      response = WikiApi.new(@wiki).query(params)
      page = response['query']['pages'][page_id.to_s]
      (page['revisions'] || []).each do |r|
          revisions << {"revid": r['revid'], "user": r['user'], "timestamp": r['timestamp'], "size": r['size']}
      end
      
      break unless response['continue']
      params.merge!(response['continue'].slice('rvcontinue', 'continue'))
    end
    revisions
  end

  def score_revisions(rev_ids, wiki)
    LiftWingApi.new(wiki).get_revision_data(rev_ids)
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
