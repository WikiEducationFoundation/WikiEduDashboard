# frozen_string_literal: true
require './lib/course_show_endpoints'
# requests to courses/:school/:titleterm(/:endpoint(/*any)) should come here

module Courses
  class ShowController < ApplicationController
    include CourseHelper
    include CourseShowConstraints
    include CourseShowEndPoints
    # this defines a controller action for each endpoint defined in lib/course_show_constraints.
    # they all do the same thing at the controller level.
    # we are also supporting the default endpoint `overview`.
    (ENDPOINTS + ['overview']).each do |endpoint|
      define_method(endpoint) do
        @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")
        verify_edit_credentials { return }
        protect_privacy { return }
        set_endpoint
        set_limit

        view_to_render = endpoint == 'overview' ? "courses/#{endpoint}" : nil
        respond_to do |format|
          format.html { render 'courses/show' }
          format.json { render view_to_render }
        end
      end
    end

    private

    # If the user could make an edit to the course, this verifies that
    # their tokens are working. If their credentials are found to be invalid,
    # they get logged out immediately, and this method redirects them to the home
    # page, so that they don't make edits that fail upon save.
    # We don't need to do this too often, though.
    def verify_edit_credentials
      return if Features.disable_wiki_output?
      return unless current_user&.can_edit?(@course)
      return if current_user.wiki_token && current_user.updated_at > 12.hours.ago
      return if WikiEdits.new.oauth_credentials_valid?(current_user)
      redirect_to root_path
      yield
    end

    def protect_privacy
      return unless @course.private
      return if current_user&.can_edit?(@course)
      raise ActionController::RoutingError, 'not found'
    end

    # Show responds to multiple endpoints to provide different sets of json data
    # about a course. Checking for a valid endpoint prevents an arbitrary render
    # vulnerability.
    def set_endpoint
      @endpoint = params[:endpoint] if ENDPOINTS.include?(params[:endpoint])
    end

    def set_limit
      case params[:endpoint]
      when 'revisions', 'articles'
        @limit = params[:limit]
      end
    end
  end
end
