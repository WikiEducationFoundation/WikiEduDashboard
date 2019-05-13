# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/monthly_report"
require_dependency "#{Rails.root}/lib/analytics/course_statistics"
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_edits_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_students_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/ungreeted_list"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  layout 'admin'
  include CourseHelper
  before_action :require_signed_in, only: :ungreeted
  before_action :set_course, only: %i[course_csv course_edits_csv course_uploads_csv
                                      course_students_csv course_articles_csv]

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

  def usage
    @user_count = User.count
    @logged_in_count = User.where.not(first_login: nil).count
    @course_instructor_count = CoursesUsers.with_instructor_role.pluck(:user_id).uniq.count
    @home_wiki_count = Course.all.pluck(:home_wiki_id).uniq.count
    @total_wikis_touched = Wiki.count
    @active_editors_by_month = [["2019-05-01", 1070], ["2019-04-01", 3444], ["2019-03-01", 2608], ["2019-02-01", 3030], ["2019-01-01", 1522], ["2018-12-01", 2040], ["2018-11-01", 3474], ["2018-10-01", 3510], ["2018-09-01", 2634], ["2018-08-01", 479], ["2018-07-01", 312], ["2018-06-01", 401], ["2018-05-01", 1259], ["2018-04-01", 3462], ["2018-03-01", 3456], ["2018-02-01", 3028], ["2018-01-01", 2297], ["2017-12-01", 1553], ["2017-11-01", 3190], ["2017-10-01", 3164], ["2017-09-01", 2347], ["2017-08-01", 416], ["2017-07-01", 232], ["2017-06-01", 403], ["2017-05-01", 1369], ["2017-04-01", 2921], ["2017-03-01", 2693], ["2017-02-01", 2538], ["2017-01-01", 1727], ["2016-12-01", 1287], ["2016-11-01", 2618], ["2016-10-01", 2658], ["2016-09-01", 1928], ["2016-08-01", 305], ["2016-07-01", 96], ["2016-06-01", 211]]
  end

  def active_editors
    @active_editors_by_month = []
    36.times do |i|
      month = i.months.ago.month
      year = i.months.ago.year
      active_editor_count = Revision.where('extract(month from date) = ?', month).where('extract(year from date) = ?', year).group('user_id').having('count(*) > 4').count.count
      @active_editors_by_month << ["#{year}-#{month}-01".to_date, active_editor_count]
    end
  end

  def ungreeted
    send_data UngreetedList.new(current_user).csv,
              filename: "ungreeted-#{current_user.username}-#{Time.zone.today}.csv"
  end

  def course_csv
    send_data CourseCsvBuilder.new(@course, per_wiki: true).generate_csv,
              filename: "#{@course.slug}-#{Time.zone.today}.csv"
  end

  def course_edits_csv
    course = find_course_by_slug(params[:course])
    send_data CourseEditsCsvBuilder.new(course).generate_csv,
              filename: "#{course.slug}-edits-#{Time.zone.today}.csv"
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

  def all_courses_csv
    send_data CampaignCsvBuilder.new(nil).courses_to_csv,
              filename: "all_courses-#{Time.zone.today}.csv"
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

  def set_course
    @course = find_course_by_slug(params[:course])
  end

  def set_campaigns
    @campaign_1 = Campaign.find(params[:campaign_1][:id])
    @campaign_2 = Campaign.find(params[:campaign_2][:id])
  end
end
