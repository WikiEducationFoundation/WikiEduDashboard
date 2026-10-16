# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/timeslice_edit_counts"

# Stores the edit counts that only article course timeslices hold in the course's
# CourseStat, so the CSVs can still report them once the timeslices are purged.
class StoreTimesliceEditCounts
  NAMESPACE_KEY = 'edits_by_namespace'
  WIKI_KEY = 'edits_by_wiki'
  STATS_HASH_KEYS = [NAMESPACE_KEY, WIKI_KEY].freeze

  def initialize(course)
    @course = course
    store
  end

  private

  def store
    course_stat = CourseStat.find_or_create_by(course_id: @course.id)
    course_stat.stats_hash[NAMESPACE_KEY] = TimesliceEditCounts.by_namespace(@course)
    course_stat.stats_hash[WIKI_KEY] = TimesliceEditCounts.by_wiki(@course)
    course_stat.save!
  end
end
