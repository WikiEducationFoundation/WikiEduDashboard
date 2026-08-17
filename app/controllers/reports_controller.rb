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
                         course_wikidata_csv course_retention_csv all_courses_and_instructors_csv
                         system_csv]
  before_action :set_campaign, only: %i[campaign_courses_csv campaign_articles_csv
                                        campaign_students_csv campaign_instructors_csv
                                        campaign_wikidata_csv]
  before_action :set_course, only: %i[course_csv course_uploads_csv
                                      course_students_csv course_articles_csv
                                      course_wikidata_csv course_retention_csv]

  before_action :set_sidekiq_job_context
  before_action :require_admin_permissions,
                only: %i[all_courses_and_instructors_csv course_retention_csv system_csv]
  before_action :validate_system_csv_filters!, only: [:system_csv]
  before_action :require_fellows_cohort, only: [:course_retention_csv]

  #######################
  # CSV-related actions #
  #######################

  CSV_PATH = '/system/analytics'
  SYSTEM_CSV_FILENAME_PREFIXES = {
    campaign_slug: 'campaign',
    start_date: 'from',
    end_date: 'to',
    wiki_domain: 'wiki',
    course_type: 'type',
    status: 'status'
  }.freeze

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

  def course_retention_csv
    csv_of('course_retention')
  end

  def all_courses_and_instructors_csv
    filename = "all-courses-and-instructors-#{Time.zone.today}.csv"

    if File.exist?("public#{CSV_PATH}/#{filename}")
      redirect_to "#{CSV_PATH}/#{filename}"
    else
      ReportCsvWorker.generate_csv(
        source: nil,
        filename: filename,
        type: 'all_courses_and_instructors',
        include_course: nil
      )
      render plain: 'This file is being generated. Please try again shortly.', status: :ok
    end
  end

  # Admin-only system-wide CSV export with dynamic filters.
  # Returns JSON: { status: 'ready', url: ... } or { status: 'generating' } (202).
  def system_csv
    filters = system_csv_filters
    filename = build_system_csv_filename(filters)

    if File.exist?("public#{CSV_PATH}/#{filename}")
      render json: { status: 'ready', url: "#{CSV_PATH}/#{filename}" }
    else
      ReportCsvWorker.generate_csv(source: nil, filename:, type: 'system_csv',
                                   include_course: nil, filters:)
      render json: { status: 'generating' }, status: :accepted
    end
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

  # The retention predictors report is only defined for Scholars & Scientists
  # (FellowsCohort) courses.
  def require_fellows_cohort
    return if @course.is_a?(FellowsCohort)
    raise ActionController::RoutingError.new('Not Found'),
          'Report not available for this course type'
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
    params.permit(:slug, :course)
  end

  def system_csv_filters
    params.permit(:campaign_slug, :start_date, :end_date,
                  :wiki_domain, :course_type, :status)
          .to_h.symbolize_keys
          .reject { |_, v| v.blank? }
  end

  def validate_system_csv_filters!
    errors = SystemCsvFilterValidator.new(system_csv_filters).errors
    return if errors.empty?
    render json: { error: errors.join(', ') },
           status: :unprocessable_content
  end

  def build_system_csv_filename(filters)
    filter_parts = SYSTEM_CSV_FILENAME_PREFIXES.filter_map do |key, prefix|
      "#{prefix}-#{filters[key]}" if filters[key].present?
    end
    parts = ['system-csv', *filter_parts, Time.zone.today.to_s]
    "#{parts.join('-')}.csv".tr('/', '-')
  end

  def course_report?(type)
    type.start_with?('course')
  end
end
