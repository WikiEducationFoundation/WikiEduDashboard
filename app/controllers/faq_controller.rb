# frozen_string_literal: true

class FaqController < ApplicationController
  before_action :require_admin_permissions, only: [:edit, :update, :destroy, :new, :create]

  DEFAULT_TOPIC = 'top'
  SPECIAL_FAQ = ['Wiki Education News', 'Programs & Events Dashboard News'].freeze

  def index # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @query = params[:search] if params[:search].present?
    @topic_slug = params[:topic] || DEFAULT_TOPIC unless @query || params[:all]
    @faqs = if @query
              log_to_sentry
              all_faqs = Faq.find_by_fuzzy_question_and_answer(@query) # rubocop:disable Rails/DynamicFindBy
              @faqs = all_faqs.reject { |faq| SPECIAL_FAQ.include?(faq.title) } # Filter out special FAQs # rubocop:disable Layout/LineLength
            elsif params[:all]
              Faq.where.not(title: SPECIAL_FAQ)
            else
              FaqTopic.new(@topic_slug).faqs
            end
  end

  def handle_special_faq_query
    news_title = params[:id]
    news_details = Faq.where(title: news_title)
    render json: { newsDetails: news_details }
  end

  def show
    @faq = Faq.find(params[:id])
  end

  def new
    @faq = Faq.new
  end

  def create
    @faq = Faq.create!(update_params)
    return if handle_special_faq
    redirect_to faq_path(@faq)
  end

  def edit
    @faq = Faq.find(params[:id])
  end

  def update
    @faq = Faq.find(params[:id])
    @faq.update!(update_params)
    return if handle_special_faq
    redirect_to faq_path(@faq)
  end

  def destroy
    @faq = Faq.find(params[:id])
    @faq.destroy!
    return if handle_special_faq
    redirect_to '/faq'
  end

  private

  def handle_special_faq
    return render(json: @faq.as_json) if SPECIAL_FAQ.include?(@faq.title)
  end

  def update_params
    params.require(:faq).permit(:title, :content)
  end

  def log_to_sentry
    # Logging to see how this feature gets used
    Sentry.capture_message 'FAQ query',
                           level: 'info',
                           tags: { 'source' => params[:source], 'query' => @query },
                           extra: { query: @query, username: current_user&.username }
  end
end
