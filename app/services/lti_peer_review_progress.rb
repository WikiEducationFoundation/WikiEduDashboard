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
# done. Peer reviews are `reviewing`-role Assignments; what counts as one being
# done is either the student marking the review complete or their review page
# existing — see #completed?. Being *assigned* a review is not doing it, which is
# why the assignment's existence isn't the measure (the random assigner hands them
# out in bulk).
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

  # Moves on every completed review, since both the fraction and the comment do.
  # That made this the one instructor-graded column whose progress could push
  # twice, which staging showed destroys the instructor's grade — so what limits
  # the pushes now is SyncLtiGrades#already_reported?, not this hash. Left
  # progress-sensitive deliberately: it describes what would be reported, and the
  # decision about how often to report belongs to the sync.
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

  # Either signal counts, because they fail in opposite directions and both live in
  # `flags[:review]` under different keys:
  #
  #   - `:status` reaching PEER_REVIEW_COMPLETED — the student's own progress
  #     through the review steps (AssignmentsController#update_status). Immediate,
  #     and for an instructor-graded column it's the right trigger: the student
  #     saying they're finished is what asks the instructor to look.
  #   - `:review`, the review page existing. The artifact, so it catches a student
  #     who wrote the review without clicking through the steps — but it's written
  #     only by CheckAssignmentStatus, which runs from the constant update cycle
  #     (lib/data_cycle/constant_update.rb), so it trails the work by up to a
  #     cycle. On the strength of that flag alone a finished review read as "0 of
  #     2" until the cycle caught up (operator decision 2026-08-04).
  def completed?(review)
    review.status == AssignmentPipeline::ReviewStatuses::PEER_REVIEW_COMPLETED ||
      review.peer_review_sandbox_status !=
        AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST
  end

  def compute_comment
    return nil unless @expected.positive?

    "#{completed_count} of #{@expected} peer reviews completed"
  end
end
