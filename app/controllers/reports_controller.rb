# frozen_string_literal: true

require_dependency "#{Rails.root}/app/workers/report_csv_worker"

#= Controller for report CSV generation (asynchronously)
# This is used for CSV reports that may be too heavy to be generated during a web request
class ReportsController < ApplicationController
  include CourseHelper
  before_action :require_signed_in,
                only: %i[campaign_instructors_csv campaign_courses_csv campaign_articles_csv
                         campaign_students_csv campaign_wikidata_csv course_csv
                         course_uploads_csv course_students_csv course_articles_csv
                         course_wikidata_csv]
  before_action :set_campaign, only: %i[campaign_courses_csv campaign_articles_csv
                                        campaign_students_csv campaign_instructors_csv
                                        campaign_wikidata_csv]
  before_action :set_course, only: %i[course_csv course_uploads_csv
                                      course_students_csv course_articles_csv
                                      course_wikidata_csv]

  before_action :set_sidekiq_job_context

  #######################
  # CSV-related actions #
  #######################

  CSV_PATH = '/system/analytics'

  def set_sidekiq_job_context
    SidekiqJobContext.username = current_user.username if current_user
  end

  def campaign_students_csv
    csv_of('campaign_students')
  end

  def campaign_instructors_csv
    csv_of('campaign_instructors')
  end

  def campaign_courses_csv
    csv_of('campaign_courses')
  end

  def campaign_articles_csv
    csv_of('campaign_articles')
  end

  def campaign_wikidata_csv
    csv_of('campaign_wikidata')
  end

  def course_csv
    csv_of('course_overview')
  end

  def course_uploads_csv
    csv_of('course_uploads')
  end

  def course_students_csv
    csv_of('course_editors')
  end

  def course_articles_csv
    csv_of('course_articles')
  end

  def course_wikidata_csv
    csv_of('course_wikidata')
  end

  private

  def set_course
    @course = find_course_by_slug(csv_params[:course])
  end

  def set_campaign
    @campaign = Campaign.find_by(slug: csv_params[:slug])
    return if @campaign
    raise ActionController::RoutingError.new('Not Found'), 'Campaign does not exist'
  end

  def csv_of(type)
    filename = build_filename(type)
    if File.exist? "public#{CSV_PATH}/#{filename}"
      redirect_to "#{CSV_PATH}/#{filename}"
    else
      ReportCsvWorker.generate_csv(source: @course || @campaign, filename:, type:,
                                   include_course: csv_params[:course])
      render plain: 'This file is being generated. Please try again shortly.', status: :ok
    end
  end

  # Builds the filename for a report of the given type, based on wether @course is defined
  # or @campaign is defined
  def build_filename(type)
    # Filename does not have to contain '/' char because it's interpreted as a route
    return "#{@course.slug}-#{type}-#{Time.zone.today}.csv".tr('/', '-') if course_report?(type)

    include_course_segment = csv_params[:course] ? '-with_courses' : ''
    "#{@campaign.slug}-#{type}#{include_course_segment}-#{Time.zone.today}.csv".tr('/', '-')
  end

  def csv_params
    params.permit(:slug, :course, :format)
  end

  def course_report?(type)
    type.start_with?('course')
  end
end
