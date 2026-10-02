# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/roster"

module StudentProgress
  # The trackable structure of a course's timeline, independent of any student:
  # which blocks carry trainings and exercises, each module's due date, and
  # where the peer-review stage sits. Reads a Roster's blocks and modules, so it
  # adds no queries of its own; one built from a Roster with no users costs the
  # blocks and modules queries alone.
  class Timeline
    # Exercises whose outcome is *which article* the student took on, not
    # whether they ticked a box. Keyed on module slug; Wiki Ed's training
    # library only.
    ARTICLE_SELECTION_SLUGS = %w[choose-topic-exercise choose-topic-from-list-exercise].freeze

    # Exercises done on the student's assigned article without being tied to
    # one of its subpages. Together with the article-stage exercises
    # (#article_stage_for) these are the exercises about the article; the list
    # matches the Canvas views' article-panel exercises.
    ARTICLE_WORK_SLUGS = %w[continue-improving-exercise].freeze

    # How the peer-review stage is identified on the timeline: by block title.
    # The wizard writes "Peer review an article" / "…two articles" / "…three
    # articles" for the work itself and "Peer reviews are complete" for the
    # milestone closing the stage — and none of those blocks carries a training
    # module, peer review having neither an exercise nor an assigned training.
    #
    # An earlier version looked for a `peer-review` training module and found
    # nothing on any real timeline (found in the 2026-08-04 Canvas walkthrough;
    # title-matching confirmed by the operator as the intended signal).
    #
    # Anchored at the start on purpose: "Respond to your peer review" is a
    # separate, later block and must not be mistaken for the stage's end.
    PEER_REVIEW_TITLE = /\Apeer review/i

    def initialize(roster)
      @roster = roster
      @course = roster.course
    end

    # Blocks carrying at least one module, in timeline order.
    def module_blocks
      @module_blocks ||= @roster.blocks.select { |block| @roster.modules_for(block).any? }
    end

    def exercise_blocks
      @exercise_blocks ||= module_blocks.select { |block| modules_for(block).any?(&:exercise?) }
    end

    # Blocks with at least one training-kind module (not exercises, not
    # discussions).
    def training_blocks
      @training_blocks ||= module_blocks.select do |block|
        modules_for(block).any? { |mod| mod.kind == TrainingModule::Kinds::TRAINING }
      end
    end

    def modules_for(block)
      @roster.modules_for(block)
    end

    # Training-kind modules in timeline order: by the first block each appears
    # in, then its position in that block.
    def training_modules
      @training_modules ||= modules_in_timeline_order
                            .select { |mod| mod.kind == TrainingModule::Kinds::TRAINING }
    end

    # Exercise modules in timeline order, likewise.
    def exercise_modules
      @exercise_modules ||= modules_in_timeline_order.select(&:exercise?)
    end

    # The first block in timeline order that carries this module.
    def block_for(training_module)
      first_block_by_module_id[training_module.id]
    end

    # A module's due date: its first block's (explicit, or the end of the
    # block's week; see BlockDateManager). Nil for a module not on the timeline.
    def due_date_for(training_module)
      block_for(training_module)&.calculated_due_date
    end

    # Which piece of a student's article an exercise is about: :selection for
    # the choose-an-article exercises, or the assigned article's subpage it is
    # done on (:bibliography, :outline). Nil for exercises about something else.
    def article_stage_for(training_module)
      return :selection if ARTICLE_SELECTION_SLUGS.include?(training_module.slug)

      training_module.assignment_sandbox_location&.downcase&.to_sym
    end

    # Whether an exercise is part of the student's work on their assigned article.
    def article_exercise?(training_module)
      training_module.exercise? &&
        (article_stage_for(training_module).present? ||
         ARTICLE_WORK_SLUGS.include?(training_module.slug))
    end

    def peer_reviews_expected?
      @course.peer_review_count.to_i.positive?
    end

    # The LAST peer-review block by timeline position. The stage spans a couple
    # of blocks — the reviewing itself, then the milestone that closes it — and
    # "your reviews are done by here" is the end of the stage. Nil when no block
    # is titled for it (an instructor who retitled the block, or a hand-built
    # timeline).
    def peer_review_block
      return @peer_review_block if defined?(@peer_review_block)

      @peer_review_block = @roster.blocks.reverse
                                  .find { |block| block.title.to_s.match?(PEER_REVIEW_TITLE) }
    end

    # [week order, block order]: where a block sits, for sorting other things
    # into timeline order. A block with no order counts as its week's first, as
    # in Roster#blocks.
    def position(block)
      [block.week.order, block.order.to_i]
    end

    private

    def modules_in_timeline_order
      @modules_in_timeline_order ||= module_blocks.flat_map { |block| modules_for(block) }.uniq
    end

    def first_block_by_module_id
      @first_block_by_module_id ||= module_blocks.reverse.each_with_object({}) do |block, index|
        block.training_module_ids.each { |id| index[id] = block }
      end
    end
  end
end
