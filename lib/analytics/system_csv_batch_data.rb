# frozen_string_literal: true

# Loads the per-course data that SystemCsvBuilder needs for one batch of
# courses, with one query per kind of data rather than per course.
class SystemCsvBatchData
  attr_reader :tags, :revision_counts, :new_editor_counts, :retained_editor_counts,
              :facilitator_usernames, :wikis

  def initialize(batch)
    course_ids = batch.map(&:id)
    @tags = fetch_tags(course_ids)
    @revision_counts = fetch_revision_counts(course_ids)
    @new_editor_counts = fetch_new_editor_counts(course_ids)
    @retained_editor_counts = fetch_retained_editor_counts(course_ids)
    @facilitator_usernames = fetch_facilitator_usernames(course_ids)
    @wikis = fetch_wikis(batch)
  end

  private

  def fetch_tags(course_ids)
    return {} if course_ids.empty?

    Tag
      .where(course_id: course_ids, tag: %w[first_time_instructor returning_instructor])
      .select(:tag, :course_id)
      .group_by(&:course_id)
  end

  # Aggregates revision counts for tracked timeslices across namespaces.
  # Note: Follows CampaignCsvBuilder precedent by aggregating all tracked timeslices
  # per course in a single bulk query for batch performance efficiency across large course sets.
  # For article-scoped programs, canonical single-course CSVs filter by scoped_article_ids,
  # but bulk exports (Campaign and System CSVs) use bulk tracked timeslices.
  def fetch_revision_counts(course_ids)
    return {} if course_ids.empty?

    namespaces = [
      Article::Namespaces::MAINSPACE,
      Article::Namespaces::TALK,
      Article::Namespaces::USER
    ]
    ArticleCourseTimeslice
      .where(tracked: true, course_id: course_ids)
      .select(:revision_count, :course_id)
      .joins(:article)
      .where(articles: { namespace: namespaces })
      .group(:course_id, :namespace)
      .sum(:revision_count)
  end

  def fetch_new_editor_counts(course_ids)
    return {} if course_ids.empty?

    User
      .joins(courses_users: :course)
      .where(courses_users: { course_id: course_ids, role: CoursesUsers::Roles::STUDENT_ROLE })
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .group('courses_users.course_id')
      .count
  end

  def fetch_retained_editor_counts(course_ids)
    return {} if course_ids.empty?

    CoursesUsers
      .joins(:course, :user)
      .where(courses_users: { course_id: course_ids,
                              role: CoursesUsers::Roles::STUDENT_ROLE,
                              retained_after_course: true })
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .group('courses_users.course_id')
      .count
  end

  # Returns { course_id => [username, ...] } for each course's facilitators.
  def fetch_facilitator_usernames(course_ids)
    return {} if course_ids.empty?

    CoursesUsers
      .joins(:user)
      .where(course_id: course_ids, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      .pluck(:course_id, 'users.username')
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last).sort }
  end

  def fetch_wikis(batch)
    home_wiki_ids = batch.map(&:home_wiki_id).compact.uniq
    return {} if home_wiki_ids.empty?

    Wiki.where(id: home_wiki_ids).group_by(&:id)
  end
end
