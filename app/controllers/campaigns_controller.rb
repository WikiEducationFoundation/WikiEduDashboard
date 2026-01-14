# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/ores_diff_csv_builder"

#= Controller for campaign data
class CampaignsController < ApplicationController
  layout 'admin', only: %i[index create]
  before_action :set_campaign, only: %i[overview programs articles users edit
                                        update destroy add_organizer remove_organizer
                                        remove_course ores_plot
                                        alerts active_courses]
  before_action :require_create_permissions, only: [:create]
  before_action :require_write_permissions, only: %i[update destroy add_organizer
                                                     remove_organizer remove_course edit]

  DETAILS_FIELDS = %w[title start end].freeze

  def index
    @campaign = Campaign.new
  end

  def show
    @campaign = if params[:slug] == 'current'
                  Campaign.default_campaign
                elsif params[:slug]
                  Campaign.find_by(slug: params[:slug])
                end
    respond_to do |format|
      format.json { set_presenter }
    end
  end

  def new
    redirect_to campaigns_path(create: true)
  end

  def create
    overrides = {}
    if campaign_params[:default_passcode] == 'custom'
      overrides[:default_passcode] = params[:campaign][:custom_default_passcode]
    end
    @campaign = Campaign.create campaign_params.merge(overrides)

    if @campaign.valid?
      add_organizer_to_campaign(current_user)
      redirect_to overview_campaign_path(@campaign.slug)
    else
      @campaigns = Campaign.all
      render :index
    end
  end

  def overview
    set_presenter
    @editable = current_user&.admin? || user_is_organizer?
    # @is_admin = current_user@.admin?
  end

  def articles
    respond_to do |format|
      format.html do
        set_page
        set_presenter
        # If there are more edited articles than the limit, we disable the feed of campaign articles
        if @presenter.too_many_articles?
          @too_many_message = t('campaign.too_many_articles')
          render 'too_many_articles'
          return
        end
      end
      format.json do
        set_campaign
        render json: { campaign: @campaign.slug, articles: @campaign.articles_to_json }
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def users
    respond_to do |format|
      format.html do
        set_presenter

        if @presenter.too_large?
          @too_many_message = t('campaign.too_large')
          render 'too_many_articles'
          return
        end

        @courses_users = CoursesUsers.where(
          course: @campaign.nonprivate_courses, role: CoursesUsers::Roles::STUDENT_ROLE
        ).eager_load(:user, :course)

        if params[:username].present?
          @courses_users = @courses_users.where('users.username LIKE ?', "%#{params[:username]}%")
        end

        if params[:min_revision_count].present?
          @courses_users = @courses_users.where('courses_users.revision_count >= ?',
                                                params[:min_revision_count])
        end

        if params[:max_revision_count].present?
          @courses_users = @courses_users.where('courses_users.revision_count <= ?',
                                                params[:max_revision_count])
        end

        if params[:course_title].present?
          @courses_users = @courses_users.where('courses.title LIKE ?',
                                                "%#{params[:course_title]}%")
        end

        @courses_users = @courses_users.order(revision_count: :desc)
      end

      format.json do
        set_campaign
        render json: { campaign: @campaign.slug, users: @campaign.users_to_json }
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def assignments
    set_campaign
    render json: { campaign: @campaign.slug, assignments: @campaign.assignments_to_json }
  end

  def current_alerts
    @campaign = Campaign.default_campaign

    respond_to do |format|
      format.html { render :alerts }
      format.json { render :alerts }
    end
  end

  def alerts
    respond_to do |format|
      format.html { render }
      format.json do
        @campaign = Campaign.find_by(slug: params[:slug]) if params[:slug]
      end
    end
  end

  def edit
    set_presenter
  end

  def programs
    set_page
    set_presenter
    @search_terms = params[:courses_query]
    @results = @presenter.search_courses(@search_terms) if @search_terms.present?
  end

  def ores_plot
    set_presenter
  end

  def update
    if @campaign.update(campaign_params)
      flash[:notice] = t('campaign.campaign_updated')
      redirect_to overview_campaign_path(@campaign.slug)
    else
      set_presenter
      @editable = true
      # If one of the Details fields was invalid, passing instance variable
      # used to show the Details form in 'edit mode'
      @open_details = (@campaign.errors.messages.keys & DETAILS_FIELDS).empty?
      render :edit
    end
  end

  def destroy
    @campaign.destroy
    flash[:notice] = t('campaign.campaign_deleted', title: @campaign.title)
    redirect_to campaigns_path
  end

  def add_organizer
    user = User.find_by(username: params[:username])

    if user.nil?
      flash[:error] = I18n.t('courses.error.user_exists', username: params[:username])
    else
      add_organizer_to_campaign(user)
      flash[:notice] = t('campaign.organizer_added', user: params[:username],
                                                     title: @campaign.title)
    end

    redirect_to overview_campaign_path(@campaign.slug)
  end

  def remove_organizer
    organizer = CampaignsUsers.find_by(user_id: params[:id],
                                       campaign: @campaign,
                                       role: CampaignsUsers::Roles::ORGANIZER_ROLE)
    unless organizer.nil?
      flash[:notice] = t('campaign.organizer_removed', user: organizer.user.username,
                                                       title: @campaign.title)
      organizer.destroy
    end

    redirect_to overview_campaign_path(@campaign.slug)
  end

  def remove_course
    campaigns_course = CampaignsCourses.find_by(course_id: params[:course_id],
                                                campaign_id: @campaign.id)
    result = campaigns_course&.destroy
    message = result ? 'campaign.course_removed' : 'campaign.course_already_removed'
    flash[:notice] = t(message, title: params[:course_title],
                                campaign_title: @campaign.title)
    redirect_to programs_campaign_path(@campaign.slug)
  end

  def active_courses
    presenter = CoursesPresenter.new(
      current_user:,
      campaign_param: @campaign.slug
    )
    @courses = presenter.active_courses_by_recent_edits
  end

  def statistics
    user_only = params[:user_only]
    newest = params[:newest]
    # rubocop:disable Layout/LineLength
    @campaigns = user_only == 'true' ? current_user.campaigns : Campaign.all.order(created_at: :desc)
    # rubocop:enable Layout/LineLength
    @campaigns = @campaigns.limit(10) if newest == 'true'
    render user_only == 'true' ? 'user_statistics' : 'statistics'
  end

  def featured_campaigns
    setting = Setting.find_or_create_by(key: 'featured_campaigns')
    campaign_slugs = setting.value['campaign_slugs'] ||= []
    featured_campaigns = Campaign.where(slug: campaign_slugs).pluck(:slug,
                                                                    :title).map do |slug, title|
      { slug:, title: }
    end
    render json: { featured_campaigns: }
  end

  def current_term
    redirect_to "/campaigns/#{Campaign.default_campaign.slug}/#{params[:subpage]}"
  end

  def refresh_stats
    set_campaign
    @campaign.clear_course_sums_cache

    flash[:notice] = t('campaign.refresh_campaign_stats')
    redirect_to overview_campaign_path(@campaign.slug)
  end

  private

  def require_create_permissions
    require_signed_in
    require_admin_permissions unless Features.open_course_creation?
  end

  def require_write_permissions
    return if current_user&.admin? || user_is_organizer?

    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end

  def set_campaign
    @campaign = Campaign.find_by(slug: params[:slug])
    return if @campaign
    raise ActionController::RoutingError.new('Not Found'), 'Campaign does not exist'
  end

  def set_page
    @page = params[:page]&.to_i
    @page = nil unless @page&.positive?
  end

  def set_presenter
    @presenter = CoursesPresenter.new(current_user:,
                                      campaign_param: @campaign.slug, page: @page)
  end

  def add_organizer_to_campaign(user)
    CampaignsUsers.create(user:,
                          campaign: @campaign,
                          role: CampaignsUsers::Roles::ORGANIZER_ROLE)
  end

  def user_is_organizer?
    return false unless current_user
    @campaign.campaigns_users.where(user_id: current_user.id,
                                    role: CampaignsUsers::Roles::ORGANIZER_ROLE).any?
  end

  def csv_params
    params.permit(:slug, :course)
  end

  def campaign_params
    params.require(:campaign)
          .permit(:slug, :description, :template_description, :title, :start, :end,
                  :default_course_type, :default_passcode)
  end
end
