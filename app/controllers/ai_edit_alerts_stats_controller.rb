# frozen_string_literal: true
# Controller for showing AI Alert stats
class AiEditAlertsStatsController < ApplicationController
  layout 'admin'
  before_action :check_user_auth

  def select_campaign
    @campaigns = Campaign.all
  end

  def choose_campaign
    redirect_to "/ai_edit_alerts_stats/#{params[:campaign_slug]}"
  end

  def index
    @campaign_slug = params[:campaign_slug]
    set_data
  end

  def redirect_to_default
    redirect_to "/ai_edit_alerts_stats/#{Campaign.default_campaign.slug}"
  end

  private

  RECENT_ALERTS_DAYS = 14
  MIN_ALERTS_COUNT_PER_COURSE = 3
  ALL_CAMPAIGNS = 'all_campaigns'

  def set_data
    set_campaign
    set_campaign_name
    set_alerts
    set_courses
    set_followups
    set_count_by_page_type
    set_student_count_with_multiple_alerts
    set_page_count_with_multiple_alerts
    set_alerts_with_recent_followup
    set_recent_alerts_for_students_with_multiple_alerts
    set_recent_alerts_for_mainspace
    set_historical_alerts
  end

  def all_campaigns?
    @campaign_slug == ALL_CAMPAIGNS
  end

  def set_campaign
    @campaign = all_campaigns? ? nil : Campaign.find_by(slug: @campaign_slug)
  end

  # If a campaign is specified, uses its slug. Otherwise, uses 'all campaigns'
  # because the stats are computed across all alerts without campaign scoping.
  def set_campaign_name
    @campaign_name = @campaign ? @campaign.slug : ALL_CAMPAIGNS
  end

  def set_alerts
    @alerts = if @campaign
                @campaign.alerts.where(type: 'AiEditAlert').includes(:article)
              else
                Alert.where(type: 'AiEditAlert').includes(:article)
              end
  end

  # Sets a hash of courses with more than MIN_ALERTS_COUNT_PER_COURSE
  def set_courses
    @courses = @alerts.group_by(&:course_id).values
                      .select { |alerts| alerts.count > MIN_ALERTS_COUNT_PER_COURSE }
                      .map do |alerts|
      {
        course: alerts.first.course,
        mainspace_count: alerts.count { |a| a.article.namespace == Article::Namespaces::MAINSPACE },
        users_count: alerts.map(&:user_id).uniq.count
      }
    end
  end

  def set_followups
    # Student followup is prioritized over non-student followups.
    @followups = (@alerts.map { |a| a.followup_student || a.followups.values.first }).compact
  end

  # Sets a hash of counts by page types.
  # Example:
  # {:choose_an_article=>1, :evaluate_an_article=>2, :bibliography=>1, :outline=>1, :sandbox=>2}
  def set_count_by_page_type
    @count_by_page_type = @alerts.group_by(&:page_type).transform_values(&:count)
  end

  # Sets the number of unique students with multiple alerts
  def set_student_count_with_multiple_alerts
    @student_count_with_multiple_alerts = @alerts
                                          .filter(&:prior_alert_id_for_user)
                                          .map(&:user_id).uniq.count
  end

  # Sets the number of unique pages with multiple alerts
  def set_page_count_with_multiple_alerts
    @page_count_with_multiple_alerts = @alerts
                                       .filter(&:prior_alert_id_for_page)
                                       .map(&:article_id).uniq.count
  end

  # Sets a list of alerts with a followup completed in the last RECENT_ALERTS_DAYS days.
  def set_alerts_with_recent_followup
    @alerts_with_recent_followup =
      @alerts.filter { |a| a.followup_timestamp&.> RECENT_ALERTS_DAYS.days.ago }
             .sort_by { |a| -a.followup_timestamp.to_i } # newest followups first
  end

  def recent_alerts
    @alerts.where('alerts.created_at > ?', RECENT_ALERTS_DAYS.days.ago)
  end

  # Sets a list of alerts created in the last RECENT_ALERTS_DAYS days
  # for students with previous alerts in the same campaign.
  def set_recent_alerts_for_students_with_multiple_alerts
    @recent_alerts_for_students_with_multiple_alerts =
      recent_alerts.filter(&:prior_alert_id_for_user)
                   .sort_by { |a| -a.created_at.to_i } # newest alerts first
  end

  # Sets alerts for articles in mainspace created in the last RECENT_ALERTS_DAYS days.
  def set_recent_alerts_for_mainspace
    @recent_alerts_for_mainspace = recent_alerts
                                   .where('article.namespace': Article::Namespaces::MAINSPACE)
                                   .order(created_at: :desc)
  end

  # Sets an array of hashes with date, page_type, and count for historical alerts.
  # The array covers the full date range and all page types,
  # even if the count is zero for some combinations.
  def set_historical_alerts
    count_by_date_and_type = @alerts.group_by { |a| [a.created_at.to_date, a.page_type] }
                                    .transform_values(&:count)

    # Ensure all date and page type combinations exist, even when count is zero.
    @historical_alerts = complete_hash(count_by_date_and_type)
  end

  def complete_hash(partial_stats)
    page_types = partial_stats.keys.map(&:second).uniq
    start_date = partial_stats.keys.map(&:first).min
    end_date   = partial_stats.keys.map(&:first).max

    # Create complete array
    (start_date..end_date).flat_map do |created_at|
      page_types.map do |page_type|
        { created_at: created_at.to_s,
          page_type:,
          count: partial_stats.fetch([created_at, page_type], 0) }
      end
    end
  end

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
