# frozen_string_literal: true

# Harvests the cited claims that were *added* in the exact revision a mainspace
# AiEditAlert flagged, into the verification-claim pool. The added side of the
# flagged edit is rendered (diff against the parent revision) with citations
# intact and fed through HarvestRevisionClaims, tagged with the source course's
# subject, the contributing student, and the alert itself for provenance.
# Idempotent — re-running on the same alert does not duplicate pool entries.
# Skips alerts that are not mainspace or lack the data needed to harvest.
class HarvestAiEditAlertClaims
  attr_reader :claims

  def initialize(alert)
    @alert = alert
    @claims = []
    perform
  end

  private

  def perform
    return unless harvestable?
    html = revision_diff_html
    return if html.nil?
    @claims = harvest(html)
  end

  def harvestable?
    @alert.is_a?(AiEditAlert) && @alert.mainspace? &&
      @alert.revision_id.present? && wiki.present?
  end

  def wiki
    @wiki ||= @alert.article&.wiki
  end

  def revision_diff_html
    GetRevisionHtmlWithCitations.new(@alert.revision_id, wiki, diff_mode: true).html
  end

  def harvest(html)
    article = @alert.article
    HarvestRevisionClaims.new(
      html:, wiki:, subject: @alert.course&.subject, article:,
      article_title: article.title, mw_rev_id: @alert.revision_id,
      source_course: @alert.course, courses_user:, alert: @alert
    ).claims
  end

  def courses_user
    return if @alert.user_id.nil? || @alert.course_id.nil?
    CoursesUsers.find_by(user_id: @alert.user_id, course_id: @alert.course_id)
  end
end
