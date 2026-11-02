# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/timeslice_edit_counts"

# Edit counts for the course, campaign and system CSVs. Uses the counts stored by
# StoreTimesliceEditCounts when a course has them (its timeslices are purged or about
# to be), and counts them from timeslices otherwise.
module CsvEditCounts
  NAMESPACE_KEY = StoreTimesliceEditCounts::NAMESPACE_KEY
  WIKI_KEY = StoreTimesliceEditCounts::WIKI_KEY

  # Returns { namespace => edits }. See TimesliceEditCounts.by_namespace.
  def self.by_namespace(course)
    stored(course, NAMESPACE_KEY) || TimesliceEditCounts.by_namespace(course)
  end

  # Returns { wiki_id => edits }. See TimesliceEditCounts.by_wiki.
  def self.by_wiki(course)
    stored(course, WIKI_KEY) || TimesliceEditCounts.by_wiki(course)
  end

  # Returns { [course_id, namespace] => edits }. The stored counts replace the counted
  # ones, since those courses' timeslices are purged or about to be.
  # See TimesliceEditCounts.by_course_and_namespace.
  def self.by_course_and_namespace(course_ids)
    counts = TimesliceEditCounts.by_course_and_namespace(course_ids)
    stored_by_course_and_namespace(course_ids).each do |course_id, edits_by_namespace|
      edits_by_namespace.each { |namespace, edits| counts[[course_id, namespace]] = edits }
    end
    counts
  end

  def self.stored(course, key)
    course.course_stat&.stats_hash&.[](key)
  end
  private_class_method :stored

  # Most courses have a CourseStat, so the SQL filter keeps from deserializing
  # the stats of every course in the batch.
  def self.stored_by_course_and_namespace(course_ids)
    CourseStat.where(course_id: course_ids)
              .where('stats_hash LIKE ?', "%#{NAMESPACE_KEY}%")
              .to_h { |course_stat| [course_stat.course_id, course_stat.stats_hash[NAMESPACE_KEY]] }
              .compact
  end
  private_class_method :stored_by_course_and_namespace
end
