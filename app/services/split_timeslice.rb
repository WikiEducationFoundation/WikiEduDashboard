# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"

class SplitTimeslice
  def initialize(course)
    @timeslice_manager = TimesliceManager.new(course)
    @timeslice_cleaner = TimesliceCleaner.new(course)
  end

  # Max desirable number of revisions per timeslice
  REVISION_THRESHOLD = 10000

  # Determines whether a timeslice needs to be split for a given wiki and date range.
  # - If splitting is required, it removes the timeslice for the old dates and
  # creates the two timeslices for the new dates.
  # Returns:
  # - A boolean indicating whether the timeslice should be split.
  # - If true, also returns an array containing the new split dates. Otherwise, it returns
  # an empty array.
  # start_date and end_date are the limits of the timeslice records
  def maybe_split(wiki, start_date, end_date, revisions)
    ActiveRecord::Base.transaction do
      @revisions = revisions
      if too_many_revisions?(wiki)
        result = true, split_timeslice(wiki, start_date, end_date)
      else
        result = false, []
      end
      result
    end
  end

  private

  def too_many_revisions?(wiki)
    @revisions[wiki][:revisions].count(&:scoped) > REVISION_THRESHOLD
  end

  def split_timeslice(wiki, start_date, end_date)
    # Delete course wiki timeslice that exceeds REVISION_THRESHOLD. Note this timeslice
    # may not exist. We also need to delete ACT and CUWT associated to that wiki and dates.
    @timeslice_cleaner.delete_timeslices_for_period([wiki], start_date, end_date)

    period_in_seconds = (end_date - start_date) / 2.0
    midpoint = start_date + period_in_seconds
    # Adjust midpoint if the number of seconds between start_data and end_date is
    # an odd number. This is because the revisions API expects start and end times in
    # YYYY-MM-DD HH:MM:SS format, which does not allow fractions of a second. Therefore,
    # if we have a fraction of a second at the midpoint, we add half a second to complete it.
    midpoint += 0.5.seconds unless (period_in_seconds.to_i - period_in_seconds).zero?

    # Create new timeslices with needs_update set to 1
    @timeslice_manager.create_course_wiki_timeslice(wiki.id, start_date, midpoint)
    @timeslice_manager.create_course_wiki_timeslice(wiki.id, midpoint, end_date)

    return [start_date, midpoint, end_date]
  end
end
