# frozen_string_literal: true

# Bundles the data for the in-Canvas assignment view of the peer-review
# (LtiLineItem::PEER_REVIEW_TYPE) gradebook column. Instructors see each
# connected student's reviews-done count; a student sees their own reviews, each
# linking to the review page they were supposed to write.
#
# Counts come from LtiPeerReviewProgress — the same calculation behind what's
# reported to Canvas — so this view can't disagree with the gradebook.
class PeerReviewAssignmentViewContext
  include LtiRosterFocus

  Row = Struct.new(:name, :completed_count, :total_count, :reviews, keyword_init: true) do
    def done?
      total_count.positive? && completed_count >= total_count
    end

    # Three states, like the trainings roll-up: a student who has done one of two
    # reviews must not look like one who has done none.
    def progress_state
      return :complete if done?
      return :partial if completed_count.positive?

      :none
    end
  end

  ReviewRow = Struct.new(:article_title, :article_url, :review_url, :completed,
                         keyword_init: true) do
    def completed?
      completed
    end
  end

  attr_reader :line_item, :course

  def initialize(line_item:, user:, instructor:, focus_user: nil)
    @line_item = line_item
    @user = user
    @instructor = instructor
    @focus_user = focus_user
    @binding = line_item.lti_course_binding
    @course = @binding.course
  end

  def instructor?
    @instructor
  end

  def title
    @line_item.label
  end

  def expected_count
    progress_for(@user || student_contexts.first&.user)&.total_count.to_i
  end

  # One row per connected student, each listing the reviews that student was
  # assigned — which articles they're reviewing, not merely how many they've
  # finished. A count alone left the instructor unable to see the assignment
  # itself, the way the article columns show each student's assigned article
  # (operator decision 2026-08-04).
  #
  # A progress object each: the review statuses live in per-assignment `flags`,
  # so there is no grouped query to batch them into — and this is one row per
  # student, not per revision.
  def roster
    student_contexts.map { |context| row_for(context.user) }
  end

  def student_panel
    row_for(@user)
  end

  # The launching student's own reviews. Kept as its own name because the student
  # view reads as "your reviews" rather than as a roster row.
  def viewer_review_rows
    review_rows_for(@user)
  end

  private

  def row_for(user)
    progress = progress_for(user)
    Row.new(name: user.username, completed_count: progress.completed_count,
            total_count: progress.total_count, reviews: review_rows_for(user))
  end

  # Which article each review is of, the page it belongs on, and whether that page
  # exists yet.
  def review_rows_for(user)
    progress_for(user).review_statuses.map do |assignment, completed|
      ReviewRow.new(
        # Stored underscored; de-underscored for display like Article#full_title.
        article_title: assignment.article_title.tr('_', ' '),
        article_url: assignment.article_url,
        review_url: "#{assignment.wiki.base_url}/wiki/#{assignment.peer_review_pagename}",
        completed:
      )
    end
  end

  def progress_for(user)
    return if user.nil?

    @progress_for ||= {}
    @progress_for[user.id] ||= LtiPeerReviewProgress.new(@course, user)
  end

  # Wikipedia-linked learners on this binding, ordered for a stable roster —
  # the same set every other drill-down lists.
  def student_contexts
    @student_contexts ||=
      focused(@binding.linked_student_contexts.sort_by { |c| c.user.username })
  end
end
