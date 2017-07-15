# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/monthly_report"
require "#{Rails.root}/lib/analytics/course_statistics"
require "#{Rails.root}/lib/analytics/course_csv_builder"
require "#{Rails.root}/lib/analytics/course_edits_csv_builder"
require "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require "#{Rails.root}/lib/analytics/course_students_csv_builder"
require "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require "#{Rails.root}/lib/analytics/ungreeted_list"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  layout 'admin'
  include CourseHelper

  ########################
  # Routing entry points #
  ########################
  def index; end

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

  def ungreeted
    respond_to do |format|
      format.csv do
        send_data UngreetedList.new(current_user).csv,
                  filename: "ungreeted-#{current_user.username}-#{Time.zone.today}.csv"
      end
    end
  end

  def course_csv
    course = find_course_by_slug(params[:course])
    send_data CourseCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-#{Time.zone.today}.csv"
  end

  def course_edits_csv
    course = find_course_by_slug(params[:course])
    send_data CourseEditsCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-edits-#{Time.zone.today}.csv"
  end

  def course_uploads_csv
    course = find_course_by_slug(params[:course])
    send_data CourseUploadsCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-uploads-#{Time.zone.today}.csv"
  end

  def course_students_csv
    course = find_course_by_slug(params[:course])
    send_data CourseStudentsCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-editors-#{Time.zone.today}.csv"
  end

  def course_articles_csv
    course = find_course_by_slug(params[:course])
    send_data CourseArticlesCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-articles-#{Time.zone.today}.csv"
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

  private

  def set_campaigns
    @campaign_1 = Campaign.find(params[:campaign_1][:id])
    @campaign_2 = Campaign.find(params[:campaign_2][:id])
  end
end
