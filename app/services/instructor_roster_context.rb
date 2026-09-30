# frozen_string_literal: true

# One row per enrolled student for the LTI 1.1 instructor view inside Canvas:
# whether they have connected through Canvas, rolled-up training, exercise and
# peer-review fractions, edit statistics from the course roster, and the same
# per-student overview a student sees on their own launch, so the instructor's
# disclosure row and the student's page cannot describe the work differently.
#
# Built from the Dashboard's own enrollment (courses_users), not from LTI
# contexts: under 1.1 there is no roster service, and a student who joined with
# the passcode belongs here as much as one who launched from Canvas. Read-only;
# every link opens the Dashboard or Wikipedia in a new tab.
class InstructorRosterContext
  StudentRow = Struct.new(:username, :connected, :revision_count, :character_sum_ms,
                          :references_count, :status, :peer_review_progress, :peer_reviews,
                          :details_url, keyword_init: true)

  attr_reader :course

  def initialize(binding:)
    @binding = binding
    @course = binding.course
  end

  def rows
    @rows ||= courses_users.map { |courses_user| row_for(courses_user) }
  end

  def empty?
    rows.empty?
  end

  # Whether the course asks its students for peer reviews at all: the test
  # DeepLinkableGradables applies before offering the 1.3 peer-review column.
  # The wizard's "0 peer reviews" choice sets no flag, so an unset count means
  # none as much as an explicit zero does. LtiPeerReviewProgress assumes one
  # review when the flag is unset (the grade sync's fallback for a column that
  # was imported), which on a roster would tell an instructor who chose none
  # that every student owes one; the view leaves the column out instead.
  def peer_reviews_expected?
    @course.peer_review_count.to_i.positive?
  end

  private

  def courses_users
    @courses_users ||= CoursesUsers.where(course: @course, role: CoursesUsers::Roles::STUDENT_ROLE)
                                   .includes(:user)
                                   .sort_by { |courses_user| courses_user.user.username.downcase }
  end

  # Everything the per-student services read, fetched once for the whole class
  # rather than once per student, so an instructor launch costs a handful of
  # queries however large the enrollment (see LtiProgressPreload).
  def preload
    @preload ||= LtiProgressPreload.new(course: @course, user_ids: courses_users.map(&:user_id))
  end

  # Students with a linked launch context on this binding: the ones who have
  # opened the Dashboard from Canvas and connected an account.
  def connected_user_ids
    @connected_user_ids ||= @binding.linked_student_contexts.map(&:user_id).to_set
  end

  def row_for(courses_user)
    user = courses_user.user
    progress = LtiPeerReviewProgress.new(@course, user,
                                         assignments: preload.assignments_for(user.id))
    StudentRow.new(username: user.username, connected: connected_user_ids.include?(user.id),
                   revision_count: courses_user.revision_count,
                   character_sum_ms: courses_user.character_sum_ms,
                   references_count: courses_user.references_count,
                   status: StudentStatusContext.new(course: @course, user:, preload:),
                   peer_review_progress: progress, peer_reviews: progress.review_rows,
                   details_url: details_url_for(user))
  end

  # The student's details page on the Dashboard: everything the iframe cannot hold.
  def details_url_for(user)
    "/courses/#{@course.slug}/students/articles/#{user.url_encoded_username}"
  end
end
