# frozen_string_literal: true

# Progress on the peer-review stage for one (Course, User) — the column behind
# LtiLineItem::PEER_REVIEW_TYPE.
#
# Peer review is the one stage of the project with no exercise module of its own,
# so it never appeared in the deep-link picker and could not become a Canvas
# column at all; it does have a dated timeline block, and the course says how many
# reviews it expects (operator decision 2026-08-03).
#
# `score_given` is the fraction of the course's expected reviews this student has
# done. What counts as done is the review page existing: peer reviews are
# `reviewing`-role Assignments, and CheckAssignmentStatus records whether each
# one's `<sandbox>/<username>_Peer_Review` page has been created. Taking a review
# is not doing it, which is why the assignment's existence isn't the measure.
#
# Like the exercise columns, and unlike trainings or the account indicator, this
# is NOT a grade: a peer review's quality is the instructor's to judge, so
# SyncLtiGrades reports it as submitted-for-grading rather than as marks (see
# LtiLineItem#instructor_graded?).
class LtiPeerReviewProgress
  attr_reader :score_given, :score_maximum, :comment

  SCORE_MAXIMUM = 1.0
  # A course with the flag unset but the column imported still expects the
  # default one review — the same fallback AssignmentManager applies when
  # assigning them.
  DEFAULT_EXPECTED = 1

  def initialize(course, user)
    @course = course
    @user = user
    @expected = (course.peer_review_count || DEFAULT_EXPECTED).to_i
    @score_maximum = SCORE_MAXIMUM
    @score_given = compute_score
    @comment = compute_comment
  end

  def signature
    @signature ||= Digest::SHA1.hexdigest("peer_review|#{@score_given}|#{@comment}")
  end

  # A course that expects no reviews has nothing to report, even if the column
  # was imported before the setting changed.
  def gradable?
    @expected.positive?
  end

  # Exposed for the in-Canvas drill-down, which shows "N of M" per student plus
  # each review's own page.
  attr_reader :expected

  def completed_count
    reviews.count { |review| completed?(review) }
  end

  def total_count
    @expected
  end

  # [assignment, completed?] pairs, for the drill-down's per-review rows.
  def review_statuses
    @review_statuses ||= reviews.map { |review| [review, completed?(review)] }
  end

  private

  def reviews
    @reviews ||= Assignment.where(course_id: @course.id, user_id: @user.id,
                                  role: Assignment::Roles::REVIEWING_ROLE)
                           .includes(:wiki).to_a
  end

  # Capped at the maximum: a student who reviewed more articles than the course
  # asked for is finished, not over 100%.
  def compute_score
    return 0.0 unless @expected.positive?

    [completed_count.to_f / @expected, SCORE_MAXIMUM].min
  end

  def completed?(review)
    review.peer_review_sandbox_status !=
      AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST
  end

  def compute_comment
    return nil unless @expected.positive?

    "#{completed_count} of #{@expected} peer reviews completed"
  end
end
