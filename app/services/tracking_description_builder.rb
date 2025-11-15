# frozen_string_literal: true

class TrackingDescriptionBuilder
  def initialize(course)
    @course = course
  end

  def call
    return not_started_message if @course.start > Time.zone.now
    return no_updates_message if no_updates_possible?

    active_tracking_message
  end

  private

  def no_updates_possible?
    @course.students.empty? || @course.campaigns.empty?
  end

  def wiki_list
  wikis =
    if @course.respond_to?(:all_wikis)
      @course.all_wikis
    elsif @course.respond_to?(:wikis)
      @course.wikis
    else
      []
    end

  languages = wikis.map(&:language).compact
  languages.any? ? languages.join(', ') : 'no wikis configured'
end

  # NEW — always show something, but clarify that tracking begins later
 def no_updates_message
  start_date = @course.start&.strftime('%B %d, %Y') || "a future date"
  "This program is scheduled to begin on #{start_date}. " \
  "When it starts, edits from #{wiki_list} will be tracked automatically. "
end

  def active_tracking_message
    end_date = @course.end.strftime('%B %d, %Y')
    update_until = (@course.end + 1.week).strftime('%B %d, %Y')
    "Edits for this program from #{wiki_list} will be tracked through #{end_date}. " \
    "The dashboard will continue updating statistics until #{update_until}."
  end
end
