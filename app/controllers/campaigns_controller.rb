# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/campaign_csv_builder"
require "#{Rails.root}/lib/analytics/ores_diff_csv_builder"

#= Controller for campaign data
class CampaignsController < ApplicationController
  layout 'admin', only: %i[index create]
  before_action :set_campaign, only: %i[overview programs articles users edit
                                        update destroy add_organizer remove_organizer
                                        remove_course courses ores_plot articles_csv]
  before_action :require_create_permissions, only: [:create]
  before_action :require_write_permissions, only: %i[update destroy add_organizer
                                                     remove_organizer remove_course edit]

  DETAILS_FIELDS = %w[title start end].freeze

  def index
    @campaigns = Campaign.all
    @campaign = Campaign.new
  end

  def show
    respond_to do |format|
      format.json do
        @campaign = Campaign.find_by_slug(params[:slug]) if params[:slug]
      end
    end
  end

  def new
    redirect_to campaigns_path(create: true)
  end

  def create
    @campaign = Campaign.create(campaign_params)

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
  end

  def articles
    set_presenter
  end

  def users
    set_presenter
    @courses_users = CoursesUsers.where(
      course: @campaign.courses.nonprivate, role: CoursesUsers::Roles::STUDENT_ROLE
    ).includes(:user, :course).order(revision_count: :desc)
  end

  def edit
    set_presenter
  end

  def programs
    set_presenter
    @search_terms = params[:courses_query]
  end

  def ores_plot
    set_presenter
    @ores_plot_path = HistogramPlotter.plot(campaign: @campaign, opts: { simple: true })
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

  #######################
  # CSV-related actions #
  #######################

  def students
    csv_for_role(:students)
  end

  def instructors
    csv_for_role(:instructors)
  end

  def courses
    filename = "#{@campaign.slug}-courses-#{Time.zone.today}.csv"
    respond_to do |format|
      format.csv do
        send_data CampaignCsvBuilder.new(@campaign).courses_to_csv,
                  filename: filename
      end
    end
  end

  def articles_csv
    filename = "#{@campaign.slug}-articles-#{Time.zone.today}.csv"
    respond_to do |format|
      format.csv do
        send_data OresDiffCsvBuilder.new(@campaign.courses).articles_to_csv,
                  filename: filename
      end
    end
  end

  private

  def require_create_permissions
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

  def set_presenter
    @presenter = CoursesPresenter.new(current_user: current_user, campaign_param: @campaign.slug)
  end

  def add_organizer_to_campaign(user)
    CampaignsUsers.create(user: user,
                          campaign: @campaign,
                          role: CampaignsUsers::Roles::ORGANIZER_ROLE)
  end

  def user_is_organizer?
    return false unless current_user
    @campaign.campaigns_users.where(user_id: current_user.id,
                                    role: CampaignsUsers::Roles::ORGANIZER_ROLE).any?
  end

  def csv_for_role(role)
    set_campaign
    filename = "#{@campaign.slug}-#{role}-#{Time.zone.today}.csv"
    respond_to do |format|
      format.csv do
        send_data @campaign.users_to_csv(role, course: csv_params[:course]),
                  filename: filename
      end
    end
  end

  def csv_params
    params.permit(:slug, :course)
  end

  def campaign_params
    params.require(:campaign)
          .permit(:slug, :description, :template_description, :title, :start, :end)
  end
end
