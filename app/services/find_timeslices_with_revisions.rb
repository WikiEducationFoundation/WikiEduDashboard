# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/revision_data_manager"
require_dependency "#{Rails.root}/lib/utils/replica_timeslice_bounds"

#= Determines which of a course's wiki timeslices contain at least one tracked
# revision, using a wide-window Replica query instead of one query per
# timeslice. UpdateCourseWikiTimeslices uses this to skip fetching timeslices
# that are known to be empty — the dominant update cost for long-dormant
# courses with far-future end dates, whose ingestion watermark never advances
# past the last student edit (issue #7005).
#
# Exposes `slice_starts`: a Set of start datetimes for the timeslices that
# contain revisions, or nil if a Replica query failed — callers should fall
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
    rows = fetch_wide_window_revisions
    # nil means a Replica query failed after retries; leave slice_starts nil so
    # the caller knows the gap couldn't be checked.
    return if rows.nil?
    rev_timestamps = rows.filter_map { |row| row['rev_timestamp'] }.sort
    @slice_starts = nonempty_slice_starts(rev_timestamps)
  end

  # One query per chunk of users, each covering the whole timeslice range. The
  # user list is chunked at the same limit RevisionDataManager uses, to stay
  # within the Replica endpoint's memory limit; a wide window makes that limit
  # more relevant here, not less. Utils.chunk_requests can't be used: it maps a
  # failed chunk's nil to [], which is indistinguishable from a genuinely empty
  # result and would mark timeslices empty in error. Returns nil if any chunk
  # fails, so that the caller falls back to a full per-timeslice scan.
  def fetch_wide_window_revisions
    @course.students.each_slice(RevisionDataManager::MAX_USERNAMES)
           .each_with_object([]) do |users, rows|
      raw = query_replica(users)
      return nil unless raw.is_a?(Enumerable)
      rows.concat raw.to_a
    end
  end

  def query_replica(users)
    Replica.new(@wiki, @update_service).get_revisions_raw(users, rev_start, rev_end)
  end

  def rev_start
    @rev_start ||= ReplicaTimesliceBounds.real_start(@course, @timeslices.first.start)
  end

  def rev_end
    @rev_end ||= ReplicaTimesliceBounds.real_end(@course, @timeslices.last.end)
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
