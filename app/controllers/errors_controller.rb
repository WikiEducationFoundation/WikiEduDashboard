#= Controller for error functionality
class ErrorsController < ApplicationController
  respond_to :html, :json

  def unsupported_browser
    render status: 403
  end

  def file_not_found
    render status: 404
  end

  def unprocessable
    render status: 422
  end

  def internal_server_error
    render status: 500
  end
end
