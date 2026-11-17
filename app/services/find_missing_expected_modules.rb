# frozen_string_literal: true

# Finds which of the training modules and exercises Wiki Education expects on a
# research-and-write course timeline are missing from it, so admins can notice
# when an instructor has removed them. The expectations live in
# config/expected_training_modules.yml.
#
# A missing expectation is reported as the list of module ids that would
# satisfy it — any one of them will do.
class FindMissingExpectedModules
  CONFIG_PATH = Rails.root.join('config/expected_training_modules.yml')

  # Lists of module ids, one list per unmet expectation.
  attr_reader :missing

  def initialize(course)
    @course = course
    @missing = []
    perform
  end

  # Names for each unmet expectation, in the same shape as #missing.
  def missing_module_names
    names = TrainingModule.where(id: @missing.flatten).to_h { |tm| [tm.id, tm.translated_name] }
    @missing.map { |ids| ids.filter_map { |id| names[id] } }
  end

  private

  def perform
    @missing = find_missing if applies?
  end

  def applies?
    Features.wiki_ed? &&
      @course.is_a?(ClassroomProgramCourse) &&
      @course.tag?('research_write_assignment')
  end

  def find_missing
    present = @course.training_module_ids.to_set
    expectations.flat_map { |alternatives| unmet(alternatives, present) }
  end

  # The unmet id lists of the alternative closest to being met, or none if any
  # alternative is fully met.
  def unmet(alternatives, present)
    gaps = alternatives.map { |lists| lists.reject { |ids| present.intersect?(ids) } }
    return [] if gaps.any?(&:empty?)
    closest = gaps.each_index.max_by { |i| [alternatives[i].size - gaps[i].size, -i] }
    gaps[closest]
  end

  # Every entry normalized to a list of alternatives, each a list of id lists.
  def expectations
    YAML.safe_load_file(CONFIG_PATH)['expected'].map do |entry|
      entry.is_a?(Hash) ? entry['one_of'] : [[entry]]
    end
  end
end
