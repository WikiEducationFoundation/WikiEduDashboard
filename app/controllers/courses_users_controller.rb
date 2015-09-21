class CoursesUsersController < ApplicationController
  respond_to :json

  def index
    @courses_users = CoursesUsers.joins(:course).merge(Course.listed).where(user_id: params['user_id'].to_i)
  end

end
