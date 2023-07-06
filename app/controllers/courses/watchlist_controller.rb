# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/watchlist_edits"

class Courses::WatchlistController < ApplicationController
  include CourseHelper

  # /courses/:slug/students/add_to_watchlist
  def add_to_watchlist
    course = find_course_by_slug(params[:slug])
    wiki = course.home_wiki
    users = course.students
    array_of_users = users.map(&:user_page)
    watchlist_response = WatchlistEdits.new(wiki, current_user).watch_userpages(array_of_users)
    render json: { message: watchlist_response }
  end
end
