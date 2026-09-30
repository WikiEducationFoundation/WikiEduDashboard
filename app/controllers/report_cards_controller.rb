# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/retention_report_card"

# Admin-only report cards for Scholars & Scientists (FellowsCohort) courses, one
# per campaign, built from the RetentionStat rows UpdateRetentionStatsWorker and
# the retention_stats:backfill task store. Wiki Education Dashboard only: the
# program, and the daily job that computes the rows, exist only there.
class ReportCardsController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed
  before_action :require_admin_permissions

  # Campaigns with at least one computed Scholars & Scientists course, newest
  # first. Derived from stored data, so a campaign appears only once its courses
  # have been computed.
  def index
    @campaigns = Campaign.joins(courses: :retention_stats)
                         .where(courses: { type: 'FellowsCohort' })
                         .select('campaigns.*, COUNT(DISTINCT courses.id) AS courses_count')
                         .group('campaigns.id')
                         .order(Arel.sql('MAX(courses.start) DESC'))
  end

  def show
    campaign = Campaign.find_by(slug: params[:campaign_slug])
    raise ActionController::RoutingError, 'Not Found' unless campaign

    @report_card = RetentionReportCard.new(campaign)
    respond_to do |format|
      format.html
      format.csv { send_data @report_card.to_csv, filename: csv_filename(campaign) }
    end
  end

  private

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  def csv_filename(campaign)
    "report-card-#{campaign.slug}-#{Time.zone.today}.csv".tr('/', '-')
  end
end
