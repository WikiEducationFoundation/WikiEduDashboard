# frozen_string_literal: true
class FeedbackFormResponsesController < ApplicationController
  def new
    @subject = request.referer || params['referer']
    @feedback_form_response = FeedbackFormResponse.new
  end

  def index
    check_user_auth { return }
    @responses = FeedbackFormResponse.order(id: :desc).where.not(body: '').first(100)
    render layout: 'admin'
  end

  def show
    check_user_auth { return }
    @response = FeedbackFormResponse.find(params[:id])
    @username = User.find(@response.user_id).username if @response.user_id
  end

  def create
    f_response = FeedbackFormResponse.new(form_params)
    f_response.user_id = current_user&.id
    f_response.save
    redirect_to feedback_confirmation_path
  end

  def confirmation
  end

  private

  def form_params
    params.require(:feedback_form_response).permit(:body, :subject)
  end

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
    yield
  end
end
