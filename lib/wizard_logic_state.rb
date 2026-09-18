# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wizard_tag_writer"

# Recovers as much of a course's original wizard `logic` state as the database
# still holds.
#
# The wizard does not persist its logic: WizardTimelineManager uses it to pick
# blocks and then drops it. What survives is indirect — a Tag for options that
# carry `tag:`, and a course flag for the handful in FLAG_LOGIC. Options that
# carry `logic:` alone (graded training, the early editing exercises, article
# choosing, the discussions, the supplementary assignments) leave no trace at
# all and can never be recovered.
#
# So every answer here is three-valued. Callers get :yes, :no, or :unknown, and
# are expected to say "can't tell" rather than guess.
class WizardLogicState
  attr_reader :known

  def initialize(course, wizard_id = 'researchwrite')
    @course = course
    @wizard_id = wizard_id
    @known = {}
    derive_from_flags
    derive_from_tags
  end

  # :yes, :no or :unknown for a WizardBlockCatalog entry's conditions.
  def verdict_for(conditions, overrides = {})
    state = @known.merge(overrides)
    ifs = Array.wrap(conditions[:if])
    unlesses = Array.wrap(conditions[:unless])
    return :yes if ifs.empty? && unlesses.empty?
    return :unknown if (ifs + unlesses).any? { |key| !state.key?(key) }
    return :no unless ifs.all? { |key| state[key] }
    unlesses.any? { |key| state[key] } ? :no : :yes
  end

  def unknown_keys(candidate_keys)
    candidate_keys.uniq.reject { |key| @known.key?(key) }
  end

  private

  def derive_from_flags
    # Sandbox mode is always determinable: the rest of the app reads a missing
    # flag as "uses sandboxes" (Course#no_sandboxes?), so this does too.
    @known['no_sandboxes'] = @course.no_sandboxes?
    @known['yes_sandboxes'] = !@course.no_sandboxes?

    # Peer review count is knowable only once the flag has been written. Absent
    # it, "the instructor chose zero" is indistinguishable from "this course
    # never ran the wizard", so all three keys stay unknown.
    count = @course.flags[:peer_review_count]
    return if count.nil?
    (1..3).each { |n| @known["#{n}_peer_reviewers"] = count == n }
  end

  # A Tag records which option of a panel was chosen. When we can see a choice
  # for a panel, every option in that panel becomes determinable: the chosen
  # one is true and the rest are false, including options that carry a logic
  # key but no tag of their own. When no tag for the panel is present we learn
  # nothing — an untagged option may have been chosen, or the course may simply
  # predate the panel — so the whole panel stays unknown.
  def derive_from_tags
    tags_by_key = @course.tags.index_by(&:key)
    panels.each do |panel|
      chosen = chosen_tags(panel, tags_by_key)
      next if chosen.nil?
      Array.wrap(panel['options']).each do |option|
        @known[option['logic']] = chosen.include?(option['tag']) if option['logic']
      end
    end
  end

  def chosen_tags(panel, tags_by_key)
    key = panel['key']
    return [tags_by_key[key]&.tag].compact.presence unless nonexclusive?(key)

    chosen = tags_by_key.filter_map { |k, tag| tag.tag if k.start_with?("#{key}-") }
    chosen.presence
  end

  def nonexclusive?(key)
    WizardTagWriter::NONEXCLUSIVE_KEYS.include?(key)
  end

  def panels
    YAML.safe_load_file("#{Rails.root}/config/wizard/#{@wizard_id}/wizard.yml",
                        permitted_classes: [])
  end
end
