# frozen_string_literal: true

class FaqController < ApplicationController
  before_action :require_admin_permissions, only: [:edit, :update, :destroy, :new, :create]

  DEFAULT_TOPIC = 'top'

  def index
    @query = params[:search]
    @topic_slug = params[:topic] || DEFAULT_TOPIC
    @faqs = if @query
              log_to_sentry
              Faq.find_by_fuzzy_question_and_answer @query # rubocop:disable Rails/DynamicFindBy
            else
              FaqTopic.new(@topic_slug).faqs
            end
  end

  def show
    @faq = Faq.find(params[:id])
  end

  def new
    @faq = Faq.new
  end

  def create
    @faq = Faq.create!(update_params)
    redirect_to faq_path(@faq)
  end

  def edit
    @faq = Faq.find(params[:id])
  end

  def update
    @faq = Faq.find(params[:id])
    @faq.update!(update_params)
    redirect_to faq_path(@faq)
  end

  def destroy
    @faq = Faq.find(params[:id])
    @faq.destroy!
    redirect_to '/faq'
  end

  private

  def update_params
    params.require(:faq).permit(:title, :content)
  end

  def log_to_sentry
    # Logging to see how this feature gets used
    Raven.capture_message 'FAQ query',
                          level: 'info',
                          tags: { 'source' => params[:source], 'query' => @query },
                          extra: { query: @query, username: current_user&.username }
  end
end
