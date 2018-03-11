# frozen_string_literal: true

#= Controller for error functionality
class ErrorsController < ApplicationController
  respond_to :html, :json

  def file_not_found
    @message = getMessage
    render status: 404
  end

  def unprocessable
    render status: 422
  end

  def internal_server_error
    render status: 500
  end

  def incorrect_passcode
    render status: 401
  end

  private

  def getMessage
    if params[:endpoint] == 'overview'
      return "No such course #{params[:school]}/#{params[:titleterm]} exists."
    else
      return I18n.t "error_404.header"
    end
  end

  def login_error
    if user_signed_in?
      redirect_to root_path
    # a status in the 500 range will automatically bypass this and
    # render internal_server_error
    else
      render status: 200
    end
  end
end
