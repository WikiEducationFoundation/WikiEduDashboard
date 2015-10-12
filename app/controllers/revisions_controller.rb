#= Controller for revisions functionality
class RevisionsController < ApplicationController
  respond_to :json
  DEFAULT_REVISION_LIMIT = 10

  def index
    user = User.find(params[:user_id])
    course = Course.find(params[:course_id])
    @revisions = user.revisions
                 .where('date >= ?', course.start)
                 .where('date <= ?', course.end)
                 .order('revisions.created_at DESC')
                 .eager_load(:article)
                 .limit(params[:limit] || DEFAULT_REVISION_LIMIT)
  end
end
