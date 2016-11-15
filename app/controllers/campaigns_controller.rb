# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/campaign_csv_builder"
#= Controller for campaign data
class CampaignsController < ApplicationController
  layout 'admin', only: [:index, :create, :edit]
  before_action :require_admin_permissions,
                only: [:create, :update]
  before_action :set_campaign, only: [:overview, :programs, :edit, :update]

  def index
    @campaigns = Campaign.all
  end

  def create
    @title = create_campaign_params[:title]
    # Strip everything but letters and digits, and convert spaces to underscores
    @slug = @title.downcase.gsub(/[^\w0-9 ]/, '').tr(' ', '_')
    if already_exists?
      head :ok
      return
    end

    Campaign.create(title: @title, slug: @slug)
    redirect_to '/campaigns'
  end

  def overview
    @presenter = CoursesPresenter.new(current_user, @campaign.slug)
    @editable = current_user&.admin?
  end

  def programs
    @presenter = CoursesPresenter.new(current_user, @campaign.slug)
  end

  def edit
  end

  def update
    @campaign.update(campaign_params)
    @presenter = CoursesPresenter.new(current_user, @campaign.slug)
    flash[:notice] = t('campaign.campaign_updated')
    redirect_to overview_campaign_path(@campaign.slug)
  end

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

  def set_campaign
    @campaign = Campaign.find_by(slug: params[:slug])
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

  def already_exists?
    Campaign.exists?(slug: @slug) || Campaign.exists?(title: @title)
  end

  def create_campaign_params
    params.require(:campaign)
          .permit(:title)
  end

  def csv_params
    params.permit(:slug, :course)
  end

  def campaign_params
    params.require(:campaign)
          .permit(:slug, :description)
  end
end
