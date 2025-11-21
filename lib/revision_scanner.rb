# frozen_string_literal: true

# Finds revisions that need to be scheduled for additional investigation
class RevisionScanner
  def self.schedule_revision_checks(wiki:, revisions:, course:)
    return unless Features.wiki_ed?
    return unless wiki.en_wiki?
    return unless course.end > Time.current # Only generate alerts is course is ongoing

    new(wiki:, revisions:, course:).schedule_ai_detection
  end

  def initialize(wiki:, revisions:, course:)
    @wiki = wiki
    @revisions = revisions
    @course = course
  end

  def schedule_ai_detection
    possible_text_dump_revisions.each do |rev|
      AiDetectionWorker.schedule_check(wiki: @wiki, revision: rev, course: @course)
    end
  end

  # Approximately 6% of revisions in the dashboard.wikedu.org
  # database between January 2024 and February 2025 were
  # over 2000 characters.
  TEXT_DUMP_CHARACTERS = 2000

  # Adding a large amounts of text in one edit
  # is a simple signal to prioritize edits
  # that might be adding AI-generated text.
  def possible_text_dump_revisions
    @revisions.select { |rev| rev.characters > TEXT_DUMP_CHARACTERS }
  end
end
