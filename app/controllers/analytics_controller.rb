# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/monthly_report"
require_dependency "#{Rails.root}/lib/analytics/course_statistics"
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_students_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/ungreeted_list"
require_dependency "#{Rails.root}/lib/analytics/tagged_courses_csv_builder"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  layout 'admin'
  include CourseHelper
  before_action :require_signed_in, only: :ungreeted
  before_action :set_course, only: %i[course_csv course_uploads_csv
                                      course_students_csv course_articles_csv
                                      course_wikidata_csv]

  ########################
  # Routing entry points #
  ########################
  def index; end

  def results
    if params[:monthly_report]
      monthly_report
    elsif params[:campaign_intersection]
      campaign_intersection
    end
    render 'index'
  end

  def usage
    @user_count = User.count
    @logged_in_count = User.where.not(first_login: nil).count
    @course_instructor_count = CoursesUsers.with_instructor_role.pluck(:user_id).uniq.count
    @home_wiki_count = Course.all.pluck(:home_wiki_id).uniq.count
    @total_wikis_touched = Wiki.count
  end

  def ungreeted
    send_data UngreetedList.new(current_user).csv,
              filename: "ungreeted-#{current_user.username}-#{Time.zone.today}.csv"
  end

  def course_csv
    send_data CourseCsvBuilder.new(@course, per_wiki: true).generate_csv,
              filename: "#{@course.slug}-#{Time.zone.today}.csv"
  end

  def tagged_courses_csv
    tag = params[:tag]
    send_data TaggedCoursesCsvBuilder.new(tag).generate_csv,
              filename: "#{tag}-courses-#{Time.zone.today}.csv"
  end

  def course_uploads_csv
    send_data CourseUploadsCsvBuilder.new(@course).generate_csv,
              filename: "#{@course.slug}-uploads-#{Time.zone.today}.csv"
  end

  def course_students_csv
    send_data CourseStudentsCsvBuilder.new(@course).generate_csv,
              filename: "#{@course.slug}-editors-#{Time.zone.today}.csv"
  end

  def course_articles_csv
    send_data CourseArticlesCsvBuilder.new(@course).generate_csv,
              filename: "#{@course.slug}-articles-#{Time.zone.today}.csv"
  end

  def course_wikidata_csv
    send_data CourseWikidataCsvBuilder.new(@course).generate_csv,
              filename: "#{@course.slug}-wikidata-#{Time.zone.today}.csv"
  end

  def all_courses_csv
    send_data CampaignCsvBuilder.new(nil).courses_to_csv,
              filename: "all_courses-#{Time.zone.today}.csv"
  end

  #################
  # WMF Analytics #
  #################

  # JSON endpoints requested by Krishna Chaitanya Velaga of WMF's
  # Community Data and Evaluation team

  def all_courses
    # Anyone can get data for nonprivate courses; only admins can private course data.
    @courses = current_user&.admin? ? Course.all : Course.nonprivate
  end

  def all_campaigns
    @campaigns = Campaign.all
  end

  ###################
  # Output builders #
  ###################

  def monthly_report
    @monthly_report = MonthlyReport.run
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

  def set_course
    @course = find_course_by_slug(params[:course])
  end

  def set_campaigns
    @campaign_1 = Campaign.find(params[:campaign_1][:id])
    @campaign_2 = Campaign.find(params[:campaign_2][:id])
  end
end
