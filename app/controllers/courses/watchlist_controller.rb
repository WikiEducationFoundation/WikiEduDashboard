# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/watchlist_edits"

class Courses::WatchlistController < ApplicationController
  include CourseHelper

  # /courses/:slug/students/add_to_watchlist
  def add_to_watchlist
    course = find_course_by_slug(params[:slug])
    wiki = course.home_wiki
    array_of_users = CoursesUsers.new.user_page(course.students)
    WatchlistEdits.new(wiki, current_user).watch_userpages(array_of_users)
  end
end
