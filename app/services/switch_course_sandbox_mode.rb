# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wizard_block_catalog"
require_dependency "#{Rails.root}/lib/wizard_logic_state"
require_dependency "#{Rails.root}/lib/wizard_tag_writer"
require_dependency "#{Rails.root}/lib/timeline_group_mode"
require_dependency "#{Rails.root}/lib/alerts/check_timeline_alert_manager"

# Switches a course between drafting in sandboxes and editing live articles.
#
# This is one decision with three separate consequences, which is why doing it
# by hand goes wrong: the `no_sandboxes` course flag drives app behaviour, the
# `sandboxes` tag records the choice, and several timeline blocks exist in two
# variants gated on the same logic key. Flipping only the flag leaves a course
# whose timeline still instructs students to do the opposite.
#
# Which blocks swap is derived from the wizard's content.yml rather than listed
# here, so that editing the wizard content keeps this correct. Blocks that also
# depend on something we cannot recover about the course (individual vs group
# work, when the course has no such tag) are reported as unresolved instead of
# being guessed at.
class SwitchCourseSandboxMode
  # The sandbox choice only exists in the research-write wizard.
  WIZARD_ID = 'researchwrite'
  LOGIC_KEY = 'no_sandboxes'

  attr_reader :added_blocks, :removed_blocks, :unmatched, :unresolved,
              :inferred_group_mode

  def initialize(course, no_sandboxes:)
    @course = course
    @no_sandboxes = no_sandboxes
    @added_blocks = []
    @removed_blocks = []
    @unmatched = []
    @unresolved = []
    @to_add = []
    @to_remove = []
    @weeks_by_catalog_week = {}
    perform
  end

  private

  def perform
    @logic = WizardLogicState.new(@course, WIZARD_ID)
    @group_logic = infer_group_mode
    classify
    ActiveRecord::Base.transaction do
      update_flag
      update_tag
      swap_blocks
    end
    CheckTimelineAlertManager.new(@course)
  end

  # Four of the sandbox-dependent blocks also branch on individual vs group
  # work, and that answer is often not recorded as a tag. Rather than report
  # those as unresolved, fall back to what the existing timeline shows. Only
  # consulted when nothing was recorded; a recorded answer always wins.
  def infer_group_mode
    return {} if @logic.known.key?('working_in_groups')
    @inferred_group_mode = TimelineGroupMode.new(@course, WIZARD_ID).logic_key
    return {} unless @inferred_group_mode
    TimelineGroupMode::LOGIC_KEYS.index_with { |key| key == @inferred_group_mode }
  end

  # Compare each sandbox-dependent block's verdict now against its verdict once
  # the flag has flipped. Anything that stops qualifying comes out; anything
  # that starts qualifying goes in.
  def classify
    catalog.conditional_on(LOGIC_KEY).each do |entry|
      before = @logic.verdict_for(entry[:conditions], @group_logic)
      after = @logic.verdict_for(entry[:conditions], @group_logic.merge(sandbox_override))
      next @unresolved << summary(entry) if [before, after].include?(:unknown)
      @to_remove << entry if before == :yes && after == :no
      @to_add << entry if before == :no && after == :yes && entry[:insertable]
    end
  end

  def sandbox_override
    { LOGIC_KEY => @no_sandboxes, 'yes_sandboxes' => !@no_sandboxes }
  end

  def update_flag
    @course.flags.merge!(WizardTimelineManager::FLAG_LOGIC.fetch(flag_logic_key))
    @course.save!
  end

  def flag_logic_key
    @no_sandboxes ? LOGIC_KEY : 'yes_sandboxes'
  end

  def update_tag
    WizardTagWriter.new(@course).write_one('sandboxes', flag_logic_key)
  end

  # A course with no timeline has no blocks to swap; the flag and tag still
  # apply, and a later wizard run will build the right blocks from them.
  def swap_blocks
    return if course_weeks.empty?
    @to_remove.each { |entry| remove_block(entry) }
    @to_add.each { |entry| add_block(entry) }
  end

  # Existing blocks carry no reference back to the catalog entry that built
  # them, so they are matched on title. A block an admin has retitled will not
  # match; it is reported rather than guessed at or silently left behind.
  def remove_block(entry)
    block = course_blocks.detect { |candidate| candidate.title == entry[:title] }
    return @unmatched << summary(entry) unless block
    @weeks_by_catalog_week[entry[:week]] ||= block.week_id
    @removed_blocks << summary(entry).merge(week_id: block.week_id)
    block.destroy
  end

  def add_block(entry)
    week = week_for(entry)
    block = Block.create!(week_id: week.id, title: entry[:title], kind: entry[:kind],
                         content: entry[:content], points: entry[:points],
                         training_module_ids: entry[:training_module_ids],
                         order: (week.blocks.maximum(:order) || 0) + 1)
    @added_blocks << summary(entry).merge(block_id: block.id, week_id: week.id)
  end

  # Prefer the week a block from the same point in the wizard timeline just
  # vacated, so a swap lands where the old block was even if the course's weeks
  # were squished together at creation. Otherwise fall back to the nominal
  # position, clamped to the weeks the course actually has.
  def week_for(entry)
    week_id = @weeks_by_catalog_week[entry[:week]]
    return Week.find(week_id) if week_id
    weeks = course_weeks.to_a
    weeks[[entry[:week] - 1, weeks.size - 1].min]
  end

  # Query weeks and blocks directly rather than through the course's
  # associations. Those may already be loaded — and therefore stale — by the
  # time this runs, and this service invalidates them as it goes by deleting
  # and creating blocks.
  def course_weeks
    Week.where(course_id: @course.id).order(:order)
  end

  def course_blocks
    Block.where(week_id: Week.where(course_id: @course.id).select(:id))
  end

  def summary(entry)
    { catalog_id: entry[:id], title: entry[:title], week: entry[:week] }
  end

  def catalog
    @catalog ||= WizardBlockCatalog.new(WIZARD_ID)
  end
end
