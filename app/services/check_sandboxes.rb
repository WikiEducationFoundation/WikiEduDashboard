# frozen_string_literal: true

require_dependency Rails.root.join('lib/wiki_api')
require_dependency Rails.root.join('lib/content_evaluation/unreliable_source_detector')

# Examines the contents of userspace sandbox pages to check for problems
class CheckSandboxes
  def initialize(course:)
    @course = course
    @violations = []
  end

  # These typically contain links to Wikipedia pages (false positives),
  # and do not include new sources that should be flagged.
  IGNORED_SANDBOXES = %w[
    be_bold
    Evaluate_an_Article
    Peer_Review
  ].freeze

  def check_sandboxes
    @course.sandboxes.each do |sandbox|
      next if IGNORED_SANDBOXES.any? { |ignored| sandbox.title.include? ignored }
      check_sandbox sandbox
    end

    return @violations
  end

  private

  def check_sandbox(sandbox)
    sandbox_content = sandbox.fetch_page_content
    unreliable_sources(sandbox_content).each do |violation_comment, first_match, match_count|
      @violations << [@course.slug, sandbox.url, violation_comment, first_match, match_count]
    end
  end

  def unreliable_sources(page_text)
    UnreliableSourcesDetector.new(page_text).unreliable_sources
  end
end
