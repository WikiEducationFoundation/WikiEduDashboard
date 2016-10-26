# frozen_string_literal: true
#= Controller for campaign data
class CampaignsController < ApplicationController
  layout 'admin', only: [:index, :create, :edit]
  before_action :require_admin_permissions,
                only: [:create]

  def index
    @campaigns = Campaign.all
  end

  def create
    @title = campaign_params[:title]
    # Strip everything but letters and digits, and convert spaces to underscores
    @slug = @title.downcase.gsub(/[^\w0-9 ]/, '').tr(' ', '_')
    if already_exists?
      head :ok
      return
    end

    Campaign.create(title: @title, slug: @slug)
    redirect_to '/campaigns'
  end

  def show
    @campaign = Campaign.find_by(slug: params[:slug])
  end

  def students
    csv_for_role(:students)
  end

  def instructors
    csv_for_role(:instructors)
  end

  private

  def csv_for_role(role)
    @campaign = Campaign.find_by(slug: csv_params[:slug])
    respond_to do |format|
      format.csv do
        filename = "#{@campaign.slug}-#{role}-#{Time.zone.today}.csv"
        send_data @campaign.users_to_csv(role, course: csv_params[:course]),
                  filename: filename
      end
    end
  end

  def already_exists?
    Campaign.exists?(slug: @slug) || Campaign.exists?(title: @title)
  end

  def campaign_params
    params.require(:campaign)
          .permit(:title)
  end

  def csv_params
    params.permit(:slug, :course)
  end
end
