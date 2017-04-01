# frozen_string_literal: true
require "#{Rails.root}/lib/analytics/monthly_report"
require "#{Rails.root}/lib/analytics/course_statistics"
require "#{Rails.root}/lib/analytics/ungreeted_list"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  layout 'admin'

  ########################
  # Routing entry points #
  ########################
  def index
  end

  def results
    if params[:monthly_report]
      monthly_report
    elsif params[:campaign_stats]
      campaign_stats
    elsif params[:campaign_intersection]
      campaign_intersection
    end
    render 'index'
  end

  ###################
  # Output builders #
  ###################

  def monthly_report
    @monthly_report = MonthlyReport.run
  end

  def campaign_stats
    @campaign_stats = {}
    @articles_edited = {}
    Campaign.all.each do |campaign|
      course_ids = campaign.courses.pluck(:id)
      stats = CourseStatistics.new(course_ids, campaign: campaign.slug)
      @campaign_stats.merge! stats.report_statistics
    end
  end

  def campaign_intersection
    set_campaigns
    campaign_name = @campaign_1.title + ' + ' + @campaign_2.title
    campaign_1_course_ids = @campaign_1.courses.pluck(:id)
    course_ids = @campaign_2.courses.where(id: campaign_1_course_ids).pluck(:id)

    stats = CourseStatistics.new(course_ids, campaign: campaign_name)
    @campaign_stats = stats.report_statistics
    @articles_edited = stats.articles_edited
  end

  def ungreeted
    respond_to do |format|
      format.csv do
        send_data UngreetedList.new(current_user).csv,
                  filename: "ungreeted-#{current_user.username}-#{Time.zone.today}.csv"
      end
    end
  end

  private

  def set_campaigns
    @campaign_1 = Campaign.find(params[:campaign_1][:id])
    @campaign_2 = Campaign.find(params[:campaign_2][:id])
  end
end
