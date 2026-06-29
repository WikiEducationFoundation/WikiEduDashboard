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
    diff = GetRevisionHtmlWithCitations.new(@alert.revision_id, wiki, diff_mode: true)
    return if diff.html.nil?
    @claims = harvest(diff.html, diff.revision_timestamp)
  end

  def harvestable?
    @alert.is_a?(AiEditAlert) && @alert.mainspace? &&
      @alert.revision_id.present? && wiki.present?
  end

  def wiki
    @wiki ||= @alert.article&.wiki
  end

  def harvest(html, mw_rev_timestamp)
    article = @alert.article
    HarvestRevisionClaims.new(
      html:, wiki:, subject: @alert.course&.subject, article:,
      article_title: article.title, mw_rev_id: @alert.revision_id,
      source_course: @alert.course, courses_user:, alert: @alert,
      mw_rev_timestamp:, full_html_provider: -> { full_revision_html }
    ).claims
  end

  # The full revision rendered with all references resolved — used by
  # HarvestRevisionClaims to recover citations for named refs that the diff
  # only invoked (it fetches this lazily, so it costs nothing when every
  # cited ref was defined within the diff).
  def full_revision_html
    GetRevisionHtmlWithCitations.new(@alert.revision_id, wiki, diff_mode: false).html
  end

  def courses_user
    return if @alert.user_id.nil? || @alert.course_id.nil?
    CoursesUsers.find_by(user_id: @alert.user_id, course_id: @alert.course_id)
  end
end
