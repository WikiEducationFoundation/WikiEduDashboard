# frozen_string_literal: true

# Builds a sample from AI edit alerts whose student answered the follow-up
# questionnaire. The self-report becomes the unit's ground truth: a
# 'false_positive' answer means the student disputed the alert, while
# 'generate_text' or 'copyedit_text' means they acknowledged using AI.
class BuildAiDetectionSampleFromAlertFollowups < BuildAiDetectionSample
  AI_USE_ANSWERS = %w[generate_text copyedit_text].freeze

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
                      ground_truth: ground_truth_for(answers),
                      metadata: { 'alert_id' => alert.id, 'page_type' => alert.page_type.to_s,
                                  'ai_how_used' => answers })
  end

  def ground_truth_for(answers)
    return AiDetectionSample::SELF_REPORTED_NO_AI if answers.include?('false_positive')
    return AiDetectionSample::SELF_REPORTED_AI if answers.intersect?(AI_USE_ANSWERS)

    AiDetectionSample::UNKNOWN
  end
end
