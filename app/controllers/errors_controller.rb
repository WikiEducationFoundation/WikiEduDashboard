# frozen_string_literal: true

#= Controller for error functionality
class ErrorsController < ApplicationController
  respond_to :html, :json

  def file_not_found
    @message = not_found_message
    render status: :not_found # 404
  end

  def unprocessable
    @error = request.env['action_dispatch.exception']
    render status: :unprocessable_content # 422
  end

  def internal_server_error
    render status: :internal_server_error # 500
  end

  def incorrect_passcode
    @path = site_relative(params[:retry].to_s)
    render status: :unauthorized # 401
  end

  def login_error
    if user_signed_in?
      redirect_to root_path
    # a status in the 500 range will automatically bypass this and
    # render internal_server_error
    else
      render status: :ok # 200
    end
  end

  private

  # The passcode form submits to this path, so it must stay on this site:
  # '/...', but not '//...' or '/\...', which browsers treat as another host.
  # Browsers also drop tabs and newlines from URLs ('/<tab>/...' becomes
  # '//...'), so control characters disqualify a path too.
  def site_relative(path)
    return '' unless path.start_with?('/')
    return '' if path.start_with?('//', '/\\') || path.match?(/[[:cntrl:]]/)
    path
  end

  def not_found_message
    if params[:school] && params[:titleterm] # only if it is a course
      return I18n.t 'error_no_course.explanation', slug: "#{params[:school]}/#{params[:titleterm]}"
    end
    return I18n.t 'error_404.explanation'
  end
end
