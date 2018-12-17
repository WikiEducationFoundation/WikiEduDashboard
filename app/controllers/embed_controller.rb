# frozen_string_literal: true

#= Controller for course functionality
class EmbedController < ApplicationController
  include CourseHelper

  def course_stats
    @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")
    response.headers.delete 'X-Frame-Options'
    respond_to do |format|
      format.html { render layout: 'stats' }
    end
  end
end
