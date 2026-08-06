# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

# Lists the (article, flagged-revision) groups a student can choose from for the
# claim-verification exercise, drawn from the pre-harvested pool of claims added
# in mainspace AiEditAlert revisions. Groups are prioritized to the student's
# course: first those harvested from courses that share a subject tag (the
# `topics-*` wizard tags), then those matching the course's free-text subject,
# then the general pool — topped up in that order until the tile limit is met, so
# the picker is never empty when the pool has any entries. Pure DB query.
#
# Every one of those scopes is first narrowed to the curated rollout list
# (config/claim_verification_rollout.yml) when one is configured, so
# prioritization only ever reorders approved revisions and can never reach past
# them. That list is temporary; with it absent or empty this serves the whole
# pool, which is the behavior to expect once the rollout gate comes off.
class RelevantClaimRevisionsForCourse
  Tile = Struct.new(:article, :mw_rev_id, :claim_count, :mw_rev_timestamp,
                    keyword_init: true)

  attr_reader :tiles

  # Sized to the curated rollout list so a student can reach all of it. Revisit
  # alongside the rollout gate: against the full harvested pool this is a
  # display cap, and 25 tiles is a lot to scroll.
  DEFAULT_LIMIT = 25

  def initialize(course, limit: DEFAULT_LIMIT)
    @course = course
    @limit = limit
    @tiles = build_tiles
  end

  private

  def build_tiles
    groups = prioritized_groups
    articles = Article.where(id: groups.map(&:first)).includes(:wiki).index_by(&:id)
    groups.filter_map do |article_id, mw_rev_id, count, timestamp|
      article = articles[article_id]
      next unless article
      Tile.new(article:, mw_rev_id:, claim_count: count, mw_rev_timestamp: timestamp)
    end
  end

  # [[article_id, mw_rev_id, count, timestamp], ...] priority order, deduped, capped.
  def prioritized_groups
    seen = {}
    [subject_tag_scope, subject_scope, general_scope].compact.each do |scope|
      grouped(scope).each do |article_id, mw_rev_id, count, timestamp|
        seen[[article_id, mw_rev_id]] ||= [article_id, mw_rev_id, count, timestamp]
      end
      break if seen.size >= @limit
    end
    seen.values.first(@limit)
  end

  # The revisions in a group share one timestamp, so MAX just picks it out.
  def grouped(scope)
    scope.group(:article_id, :mw_rev_id)
         .order(Arel.sql('COUNT(*) DESC, mw_rev_id DESC')).limit(@limit)
         .pluck(:article_id, :mw_rev_id, Arel.sql('COUNT(*)'),
                Arel.sql('MAX(mw_rev_timestamp)'))
  end

  def base
    ClaimVerification::RolloutList.filter(
      VerificationClaim.where.not(alert_id: nil)
                       .where.not(article_id: nil).where.not(mw_rev_id: nil)
    )
  end

  def subject_tag_scope
    return if subject_tag_course_ids.empty?
    base.where(source_course_id: subject_tag_course_ids)
  end

  def subject_scope
    return if @course.subject.blank?
    base.for_subject(@course.subject)
  end

  def general_scope
    base
  end

  # Distinct ids of courses sharing a subject tag with the student's course;
  # resolved separately (not joined into `base`) so a source course with several
  # matching tags doesn't multiply a revision's claim count.
  def subject_tag_course_ids
    @subject_tag_course_ids ||=
      Course.joins(:tags).where(tags: { tag: subject_tags })
            .where('tags.key LIKE ?', 'topics-%').distinct.pluck(:id)
  end

  def subject_tags
    @subject_tags ||= @course.tags.where('tags.key LIKE ?', 'topics-%').pluck(:tag)
  end
end
