class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :course_slug_path
  def course_slug_path(slug)
    course_path(:id => slug).gsub("%2F", "/")
  end
end
