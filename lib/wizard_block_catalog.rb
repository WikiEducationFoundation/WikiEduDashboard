# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wizard_timeline_manager"

# A read-only, addressable view of the blocks a wizard's content.yml can build.
#
# WizardTimelineManager reads the same file once, when a course is created, and
# then discards everything it knew. This exposes those blocks as a flat catalog
# so that an admin can put one into an existing timeline afterwards — to restore
# a block that was deleted, replace one whose canonical copy has since been
# revised, or swap between two conditional variants of the same block.
#
# Entries are addressed by the `id` slug in content.yml, which exists only for
# this purpose: WizardTimelineManager strips it before saving, so it never
# reaches the blocks table.
class WizardBlockCatalog
  # Handouts blocks carry no content of their own. WizardTimelineManager builds
  # it at save time from the selected handout logic keys and destroys the block
  # if none matched, so there is nothing static to insert. They are listed, but
  # flagged not insertable, rather than hidden with no explanation.
  GENERATED_KINDS = [Block::KINDS['handouts']].freeze

  attr_reader :blocks

  def initialize(wizard_id)
    unless WizardTimelineManager::VALID_WIZARD_IDS.include?(wizard_id)
      raise WizardTimelineManager::InvalidWizardError, "Invalid wizard_id: #{wizard_id}"
    end

    @wizard_id = wizard_id
    @blocks = []
    build
  end

  def find(id)
    @blocks.find { |block| block[:id] == id }
  end

  # Every logic key any block in this wizard is conditional on.
  def condition_keys
    @blocks.flat_map { |block| block[:conditions][:if] + block[:conditions][:unless] }.uniq
  end

  # Entries whose presence depends on the given logic key, either way round.
  def conditional_on(logic_key)
    @blocks.select do |block|
      block[:conditions][:if].include?(logic_key) || block[:conditions][:unless].include?(logic_key)
    end
  end

  private

  def build
    content.each do |group, weeks|
      weeks.each_with_index do |week, index|
        Array.wrap(week['blocks']).each { |block| @blocks << entry(block, group, index + 1) }
      end
    end
  end

  def entry(block, group, week)
    {
      id: block['id'],
      group:,
      week:,
      title: block['title'],
      kind: block['kind'],
      content: block['content'],
      training_module_ids: block['training_module_ids'] || [],
      points: points_for(block),
      conditions: { if: Array.wrap(block['if']), unless: Array.wrap(block['unless']) },
      insertable: !GENERATED_KINDS.include?(block['kind'])
    }
  end

  # Mirrors WizardTimelineManager#save_block, which fills in the default for a
  # graded block that does not name its own points value.
  def points_for(block)
    return block['points'] if block['points']
    block['graded'] ? Block::DEFAULT_POINTS : nil
  end

  # `buildyourown` has an empty content file: it exists so the wizard index can
  # offer "start from scratch", and builds no blocks at all.
  def content
    YAML.safe_load_file("#{Rails.root}/config/wizard/#{@wizard_id}/content.yml",
                        permitted_classes: []) || {}
  end
end
