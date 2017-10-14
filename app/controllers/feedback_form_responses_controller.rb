# frozen_string_literal: true

class FeedbackFormResponsesController < ApplicationController
  def new
    set_subjects
    @is_training_module = true if @subject =~ %r{/training/}
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
    @user = User.find(@response.user_id) if @response.user_id
  end

  def create
    f_response = FeedbackFormResponse.new(form_params)
    f_response.user_id = current_user&.id
    f_response.save
    redirect_to feedback_confirmation_path
  end

  def confirmation; end

  private

  def set_subjects
    @subject = params['subject']
    @main_subject = params['main_subject']

    @has_explicit_subject = true if @subject
    @subject ||= request.referer || params['referer'] || ''
    @main_subject ||= @subject[/(.*) —/, 1] || @subject
  end

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
