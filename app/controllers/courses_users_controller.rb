class CoursesUsersController < ApplicationController
  respond_to :json

  def index
    @courses_users = CoursesUsers.where(user_id: params['user_id'].to_i)
  end

end
