# frozen_string_literal: true

# Builds a sample from AI edit alerts whose student answered the follow-up
# questionnaire. The answers are recorded as provenance and metadata only:
# a self-report is not trusted as ground truth, so ground_truth stays nil.
# The analysis can still use these units to surface candidates worth
# confirming by hand, e.g. disputed alerts with high scores.
class BuildAiDetectionSampleFromAlertFollowups < BuildAiDetectionSample
  def initialize(sample_name:, since: nil, verbose: false)
    super(sample_name:, verbose:)
    alerts = AiEditAlert.includes(:article, :user, course: :campaigns)
    alerts = alerts.where(created_at: since..) if since
    alerts.find_each { |alert| add_alert(alert) if alert.followup_student }
  end

  private

  def add_alert(alert)
    answers = Array(alert.followup_student[:AI_how_used]).compact_blank
    add_revision_unit(wiki: alert.wiki, rev_id: alert.revision_id, url: alert.url,
                      article_id: alert.article_id, course_id: alert.course_id,
                      campaign_slug: alert.course&.campaigns&.first&.slug,
                      namespace: alert.article&.namespace,
                      provenance: AiDetectionSample::SELF_REPORT,
                      metadata: { 'alert_id' => alert.id, 'page_type' => alert.page_type.to_s,
                                  'ai_how_used' => answers,
                                  'self_reported_false_positive' =>
                                    answers.include?('false_positive') })
  end
end
