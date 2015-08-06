#= Controller for revisions functionality
class RevisionsController < ApplicationController
  respond_to :json

  def index
    user = User.find(params[:user_id])
    course = Course.find(params[:course_id])
    @revisions = user.revisions
                 .where{ date >= my{course.start} }
                 .where{ date <= my{course.end} }
                 .order("#{params[:order]} DESC")
                 .eager_load(:article)
                 .limit(params[:limit])
  end
end
