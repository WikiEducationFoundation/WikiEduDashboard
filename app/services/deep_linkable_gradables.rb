# frozen_string_literal: true

# The set of gradables an instructor can attach to a Canvas assignment via the
# LTI deep-linking picker: one option per *exercise* Block in the course
# timeline, plus a single rolled-up "Wikipedia trainings" option when the
# course has any training modules. Each option's `resource` key is the marker
# we send to Canvas (and read back off the launch) to bind the created line
# item to its Dashboard gradable.
#
# The exercise/training classification and the line-item label format mirror
# `SyncLtiLineItems`; the two are slated to unify if line-item creation ever
# moves fully to deep linking.
class DeepLinkableGradables
  Gradable = Struct.new(:resource, :gradable_type, :gradable_id, :label, keyword_init: true)

  TRAININGS_LABEL = 'Wikipedia trainings'

  attr_reader :result

  def initialize(course)
    @course = course
    @result = perform
  end

  private

  def perform
    options = exercise_blocks.map { |block| gradable_for_block(block) }
    options.unshift(trainings_rollup) if any_trainings?
    options
  end

  def gradable_for_block(block)
    Gradable.new(resource: "Block:#{block.id}", gradable_type: 'Block',
                 gradable_id: block.id, label: label_for_block(block))
  end

  def trainings_rollup
    Gradable.new(resource: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                 gradable_id: nil, label: TRAININGS_LABEL)
  end

  def gradable_blocks
    @gradable_blocks ||=
      @course.blocks.includes(:week).to_a.select { |b| b.training_module_ids.any? }
  end

  def exercise_blocks
    gradable_blocks.select { |b| b.training_modules.any?(&:exercise?) }
  end

  def any_trainings?
    gradable_blocks.any? do |b|
      b.training_modules.any? { |m| m.kind == TrainingModule::Kinds::TRAINING }
    end
  end

  def label_for_block(block)
    LtiGradebookLabel.for_block(block)
  end
end
