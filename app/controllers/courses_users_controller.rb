# frozen_string_literal: true

#= Controller for finding the course roles for a user
class CoursesUsersController < ApplicationController
  respond_to :json

  def index
    @courses_users = CoursesUsers
                     .joins(:course)
                     .where(user_id: params['user_id'].to_i)
                     .order(id: :desc)
  end
end
