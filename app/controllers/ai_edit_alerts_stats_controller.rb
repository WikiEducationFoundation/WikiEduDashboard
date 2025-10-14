# frozen_string_literal: true
# Controller for showing AI Alert stats
class AiEditAlertsStatsController < ApplicationController
  layout 'admin'
  before_action :check_user_auth
  def index
    set_alerts
    set_followups

    respond_to do |format|
      format.html
      format.json do
        render json: {
          current_term: Campaign.default_campaign.slug,
          total_alerts: @alerts.count,
          by_page_type: count_by_page_type,
          total_followups: @followups.count,
          students_with_multiple_alerts: student_count_with_multiple_alerts,
          pages_with_multiple_alerts: page_count_with_multiple_alerts,
          false_positives: count_by_false_positives
        }
      end
    end
  end

  private

  RECENT_ALERTS_DAYS = 14

  def set_alerts
    @alerts = Campaign.default_campaign.alerts.where(type: 'AiEditAlert')
  end

  def set_followups
    # Student followup is prioritized over non-student followups.
    @followups = (@alerts.map { |a| a.followup_student || a.followups.values.first }).compact
  end

  # Returns a hash of counts by page types.
  # Example:
  # {:choose_an_article=>1, :evaluate_an_article=>2, :bibliography=>1, :outline=>1, :sandbox=>2}
  def count_by_page_type
    @alerts.group_by(&:page_type).transform_values(&:count)
  end

  # Returns the number of unique students with multiple alerts
  def student_count_with_multiple_alerts
    @alerts.filter(&:prior_alert_id_for_user).map(&:user_id).uniq.count
  end

  # Returns the number of unique pages with multiple alerts
  def page_count_with_multiple_alerts
    @alerts.filter(&:prior_alert_id_for_page).map(&:article_id).uniq.count
  end

  # Returns a list of alerts with a followup completed in the last RECENT_ALERTS_DAYS days.
  # For now, we rely on the updated_at alert field to detrmine when a followup was answered.
  def alerts_with_recent_followup
    @alerts.where('alerts.updated_at > ?', RECENT_ALERTS_DAYS.days.ago).filter(&:followup?)
  end

  # Returns a list of alerts created in the last RECENT_ALERTS_DAYS days
  # for students with previous alerts in the same campaign.
  def recent_alerts_for_students_with_multiple_alerts
    @alerts.where('alerts.created_at > ?', RECENT_ALERTS_DAYS.days.ago)
           .filter(&:prior_alert_id_for_user)
  end

  # Returns a hash of counts of false positives/ total followups.
  # If an alert didn't have a followup, it doesnt count at all in this metric.
  # Example:
  # {:false_positive=>2, :other=>2}
  def count_by_false_positives
    false_positive = @followups.count { |r| r[:AI_how_used]&.include?('false_positive') }
    return { false_positive:, other: @followups.count - false_positive }
  end

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
