# frozen_string_literal: true

#= Controller for finding the course roles for a user
class CoursesUsersController < ApplicationController
  respond_to :json
  before_action :require_signed_in
  before_action :require_self_or_admin

  def index
    @courses_users = CoursesUsers
                     .joins(:course)
                     .where(user_id: params['user_id'].to_i)
                     .order(id: :desc)
  end

  private

  def require_self_or_admin
    return if current_user.admin?
    raise NotPermittedError unless params['user_id'].to_i == current_user.id
  end
end
