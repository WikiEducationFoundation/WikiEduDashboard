# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/campaign_csv_builder"
#= Controller for campaign data
class CampaignsController < ApplicationController
  layout 'admin', only: [:index, :create, :edit]
  before_action :set_campaign, only: [:overview, :programs, :edit, :update,
                                      :destroy, :add_organizer, :remove_organizer]
  before_action :require_create_permissions, only: [:create]
  before_action :require_write_permissions, only: [:update, :destroy,
                                                   :add_organizer, :remove_organizer]

  DETAILS_FIELDS = %w(title start end).freeze

  def index
    @campaigns = Campaign.all
    @campaign = Campaign.new
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

  def programs
    set_presenter
  end

  def edit; end

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

      render :overview
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
    set_campaign
    filename = "#{@campaign.slug}-courses-#{Time.zone.today}.csv"
    respond_to do |format|
      format.csv do
        send_data CampaignCsvBuilder.new(@campaign).courses_to_csv,
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
  end

  def set_presenter
    @presenter = CoursesPresenter.new(current_user, @campaign.slug)
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
          .permit(:slug, :description, :title, :start, :end)
  end
end
