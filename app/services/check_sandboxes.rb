# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/content_evaluation/unreliable_source_detector"

# Examines the contents of userspace sandbox pages to check for problems
class CheckSandboxes
  def initialize(course:)
    @course = course
    @violations = []
  end

  def check_sandboxes
    @course.sandboxes.each do |sandbox|
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
