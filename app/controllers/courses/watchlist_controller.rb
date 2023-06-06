# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/watchlist_edits"

class Courses::WatchlistController < ApplicationController
  include CourseHelper

  # /courses/:slug/students/add_to_watchlist
  def add_to_watchlist
    course = find_course_by_slug(params[:slug])
    student_names = CoursesUsers.new.user_page(course.students)
    WatchlistEdits.new(course.home_wiki, student_names).oauth_credentials_valid?(current_user)
  end
end
