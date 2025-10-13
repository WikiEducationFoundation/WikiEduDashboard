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
          total_alerts: @alerts.count,
          by_page_type: count_by_page_type,
          total_followups: @followups.count,
          false_positives: count_by_false_positives
        }
      end
    end
  end

  private

  DAYS = 30

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
