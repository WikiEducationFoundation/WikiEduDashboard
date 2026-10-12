# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/links"
require_dependency "#{Rails.root}/lib/student_progress/roster"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

#= The course page Assignments tab's data: the course's students, the
# assignments it tracks (BuildAssignmentCatalog), how many students are where
# on each, and one assignment's per-student rows.
#
# Everything is read from one StudentProgress::Roster for the whole class, so
# a request costs the same handful of queries however large the class is.
# Summary counts need every student's state on every assignment, so all cells
# are built; only the requested assignment's are returned in full.
class AssignmentProgressPresenter
  STATES = %w[complete in_progress not_started].freeze

  attr_reader :course

  def initialize(course:)
    @course = course
  end

  def students
    @students ||= CoursesUsers.where(course: @course, role: CoursesUsers::Roles::STUDENT_ROLE)
                              .includes(:user).map(&:user)
                              .sort_by { |user| user.username.downcase }
  end

  def items
    catalog.items
  end

  def item(key)
    items.find { |candidate| candidate.key == key }
  end

  # Per assignment, how many students have completed it, are part way, or
  # haven't started, and how many are past its due date without completing.
  def summary
    items.map do |item|
      cells = rows_for(item)
      counts = STATES.index_with { |state| cells.count { |cell| cell[:state] == state } }
      { key: item.key, overdue: cells.count { |cell| cell[:overdue] }, total: cells.size,
        **counts.symbolize_keys }
    end
  end

  # One cell per student, in student order.
  def rows_for(item)
    @rows ||= {}
    @rows[item.key] ||= students.map { |user| cells.for(item, user) }
  end

  # How many students have reached each stage of the assigned article.
  def article_funnel
    item = item(BuildAssignmentCatalog::ARTICLE_KEY)
    ArticleFunnel.new(course: @course, item:, cells: rows_for(item), timeline:).to_h
  end

  # Where a module-based assignment is done, the same for every student: the
  # module's training page (an exercise's instructions) and, for an exercise
  # done in the app, its page. A slide-less in-app exercise has only the latter.
  def links_for(item)
    mod = item.training_module
    return {} if mod.nil?

    training_url = StudentProgress::Links.training_url(@course, mod) if mod.training_page?
    { training_url:,
      exercise_url: StudentProgress::Links.exercise_path_url(@course, mod) }.compact
  end

  # The steps of the article pipeline for this course (it depends on the
  # sandbox mode), for labelling each article's `status`.
  def article_statuses
    AssignmentPipeline::PIPELINES[@course.no_sandboxes? ? :no_sandbox_assignment : :assignment]
  end

  private

  def roster
    @roster ||= StudentProgress::Roster.new(course: @course, user_ids: students.map(&:id))
  end

  def timeline
    @timeline ||= StudentProgress::Timeline.new(roster)
  end

  def catalog
    @catalog ||= BuildAssignmentCatalog.new(roster:, timeline:)
  end

  def cells
    @cells ||= AssignmentProgressCells.new(roster:, timeline:)
  end
end
