# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wizard_block_catalog"

# Works out whether a course's students write individually or in groups by
# reading the timeline the wizard already built for them.
#
# The wizard records that answer as a tag, but plenty of courses have no such
# tag: clones from before the tag was carried over, hand-built timelines, and
# courses whose tags were edited. The timeline itself still holds the evidence,
# because the wizard emits a different variant of the same block for each
# answer — same title, different training modules. "Start drafting your
# contributions" gets the Drafting module for individuals and Drafting in groups
# for groups; "Begin moving your work to Wikipedia" likewise.
#
# The variants are read out of the wizard's own content.yml rather than listed
# here, so editing the wizard keeps this correct.
#
# This is evidence, not a record. An admin who has edited a block's training
# modules by hand can make it wrong, so it reports nil rather than a guess
# whenever the evidence is missing or the blocks disagree, leaving the caller
# free to decline to act.
class TimelineGroupMode
  LOGIC_KEYS = %w[working_individually working_in_groups].freeze

  # 'working_individually', 'working_in_groups', or nil when it cannot be told.
  attr_reader :logic_key

  def initialize(course, wizard_id = 'researchwrite')
    @course = course
    @catalog = WizardBlockCatalog.new(wizard_id)
    @logic_key = infer
  end

  private

  def infer
    votes = course_blocks.filter_map { |block| vote(block) }.uniq
    votes.one? ? votes.first : nil
  end

  # What one existing block says about the answer, or nil if it says nothing.
  # A block whose modules match more than one variant is no evidence at all.
  def vote(block)
    candidates = variants[block.title]
    return nil if candidates.nil?
    modules = block.training_module_ids.sort
    matches = candidates.select { |entry| entry[:training_module_ids].sort == modules }
    return nil unless matches.one?
    (matches.first[:conditions][:if] & LOGIC_KEYS).first
  end

  # Catalog entries that differ only by which group-work answer produced them,
  # keyed by the title their variants share.
  def variants
    @variants ||= @catalog.blocks
                          .select { |entry| (entry[:conditions][:if] & LOGIC_KEYS).any? }
                          .group_by { |entry| entry[:title] }
                          .select { |_title, entries| entries.many? }
  end

  # Loaded as records rather than plucked, so the serialized training_module_ids
  # column comes back as an array.
  def course_blocks
    Block.where(week_id: Week.where(course_id: @course.id).select(:id))
  end
end
