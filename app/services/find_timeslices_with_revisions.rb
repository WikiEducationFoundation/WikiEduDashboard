# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/utils/replica_timeslice_bounds"

#= Determines which of a course's wiki timeslices contain at least one tracked
# revision, using a single wide-window Replica query instead of one query per
# timeslice. UpdateCourseWikiTimeslices uses this to skip fetching timeslices
# that are known to be empty — the dominant update cost for long-dormant
# courses with far-future end dates, whose ingestion watermark never advances
# past the last student edit (issue #7005).
#
# Exposes `slice_starts`: a Set of start datetimes for the timeslices that
# contain revisions, or nil if the Replica query failed — callers should fall
# back to a full per-timeslice scan in that case.
class FindTimeslicesWithRevisions
  attr_reader :slice_starts

  # `timeslices` is a collection of CourseWikiTimeslice records for one wiki.
  def initialize(course, wiki, timeslices, update_service: nil)
    @course = course
    @wiki = wiki
    @timeslices = timeslices.sort_by(&:start)
    @update_service = update_service
    perform
  end

  private

  def perform
    return if @timeslices.empty?
    raw = fetch_wide_window_revisions
    # A non-Enumerable result means the Replica query failed after retries;
    # leave slice_starts nil so the caller knows the gap couldn't be checked.
    return unless raw.is_a?(Enumerable)
    rev_timestamps = raw.filter_map { |row| row['rev_timestamp'] }.sort
    @slice_starts = nonempty_slice_starts(rev_timestamps)
  end

  def fetch_wide_window_revisions
    Replica.new(@wiki, @update_service).get_revisions_raw(
      @course.students,
      ReplicaTimesliceBounds.real_start(@course, @timeslices.first.start),
      ReplicaTimesliceBounds.real_end(@course, @timeslices.last.end)
    )
  end

  # Replica rev_timestamps are '%Y%m%d%H%M%S' strings, the same format
  # ReplicaTimesliceBounds produces, so lexicographic comparison matches
  # chronological order and no timezone parsing is needed.
  def nonempty_slice_starts(rev_timestamps)
    @timeslices.each_with_object(Set.new) do |timeslice, starts|
      first_in_slice = rev_timestamps.bsearch do |ts|
        ts >= ReplicaTimesliceBounds.real_start(@course, timeslice.start)
      end
      next if first_in_slice.nil?
      starts << timeslice.start if within_slice?(first_in_slice, timeslice)
    end
  end

  def within_slice?(rev_timestamp, timeslice)
    rev_timestamp <= ReplicaTimesliceBounds.real_end(@course, timeslice.end)
  end
end
