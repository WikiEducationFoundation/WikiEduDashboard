# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/monthly_report"
require_dependency "#{Rails.root}/lib/analytics/course_statistics"
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/ungreeted_list"
require_dependency "#{Rails.root}/lib/analytics/tagged_courses_csv_builder"

#= Controller for analytics tools
class AnalyticsController < ApplicationController
  layout 'admin'
  include CourseHelper
  before_action :require_signed_in, only: :ungreeted

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
    @wiki_data = organize_wiki_data
  end

  def ungreeted
    send_data UngreetedList.new(current_user).csv,
              filename: "ungreeted-#{current_user.username}-#{Time.zone.today}.csv"
  end

  def tagged_courses_csv
    tag = params[:tag]
    send_data TaggedCoursesCsvBuilder.new(tag).generate_csv,
              filename: "#{tag}-courses-#{Time.zone.today}.csv"
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
    respond_to do |format|
      format.json
    end
  end

  def all_campaigns
    @campaigns = Campaign.all
    respond_to do |format|
      format.json
    end
  end

  private

  ###################
  # Output builders #
  ###################

  def organize_wiki_data
    wikis_with_counts = build_wikis_with_counts
    wikis_with_counts.sort_by! { |w| -w[:course_count] }

    {
      all: wikis_with_counts,
      by_project: wikis_with_counts.group_by { |w| w[:project] },
      by_language: group_by_language(wikis_with_counts),
      top_wikis: wikis_with_counts.first(10),
      summary: build_wiki_summary(wikis_with_counts)
    }
  end

  def build_wikis_with_counts
    course_counts = Course.group(:home_wiki_id).count
    Wiki.where(id: course_counts.keys).map do |wiki|
      { wiki: wiki, domain: wiki.domain, language: wiki.language,
        project: wiki.project, course_count: course_counts[wiki.id] || 0 }
    end
  end

  def group_by_language(wikis_with_counts)
    wikis_with_counts.group_by { |w| w[:language] }
                     .select { |lang, wikis| lang.present? && wikis.size > 1 }
  end

  def build_wiki_summary(wikis_with_counts)
    {
      total_wikis: wikis_with_counts.size,
      total_courses: wikis_with_counts.sum { |w| w[:course_count] },
      total_languages: wikis_with_counts.pluck(:language).compact.uniq.size,
      total_projects: wikis_with_counts.pluck(:project).uniq.size
    }
  end

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

  def set_campaigns
    @campaign_1 = Campaign.find(params[:campaign_1][:id])
    @campaign_2 = Campaign.find(params[:campaign_2][:id])
  end
end
