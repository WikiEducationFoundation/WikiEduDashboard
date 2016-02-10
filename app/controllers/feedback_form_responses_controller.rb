class FeedbackFormResponsesController < ApplicationController
  def new
    @subject = request.referrer || params['referrer']
    @feedback_form_response = FeedbackFormResponse.new
  end

  def index
    check_user_auth
    @responses = FeedbackFormResponse.order(id: :desc).first(50)
  end

  def show
    check_user_auth
    @response = FeedbackFormResponse.find(params[:id])
    if @response.user_id
      @username = User.find(@response.user_id).wiki_id
    else
      @username = nil
    end
  end

  def create
    f_response = FeedbackFormResponse.new(form_params)
    f_response.user_id = current_user.try(:id)
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
    return if current_user.try(:admin?)
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
