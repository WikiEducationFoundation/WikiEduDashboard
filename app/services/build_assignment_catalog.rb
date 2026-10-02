# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/peer_review_facts"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

# The assignments the course page's Assignments tab tracks for a course, in
# timeline order:
#
# - one per training module and one per exercise module on the timeline
#   (discussion modules are not tracked);
# - the assigned article, as one assignment covering all the work on it: the
#   article itself, its bibliography/outline/draft pages, the live article,
#   and the exercises about it (choosing it, the bibliography and outline
#   exercises, continuing to improve it). Those exercises are also listed as
#   exercises in their own right, so each has its own per-student rows. The
#   article sits where the first of them does (just before it), or after the
#   timeline when there are none;
# - the peer-review stage, at its timeline block, when the course expects
#   reviews or anyone has been assigned one.
class BuildAssignmentCatalog
  # `key` is stable across requests and safe in a URL path segment.
  # `title` is the module's own name; the tab labels the other kinds itself.
  # `training_modules` are the article's exercises, for the article item.
  Item = Struct.new(:key, :kind, :title, :training_module, :training_modules, :due_date,
                    keyword_init: true)

  ARTICLE_KEY = 'article'

  attr_reader :items

  def initialize(roster:, timeline:)
    @roster = roster
    @course = roster.course
    @timeline = timeline
    @items = build
  end

  private

  # Sorted by position, then by the order built (sort_by alone isn't stable),
  # so the article comes before the exercise whose position it shares.
  def build
    ([article_item] + module_items + peer_review_items)
      .each_with_index.sort_by { |(position, _item), index| [position, index] }
      .map { |(_position, item), _index| item }
  end

  def module_items
    (@timeline.training_modules + @timeline.exercise_modules).map do |mod|
      [module_position(mod), module_item(mod)]
    end
  end

  def module_position(mod)
    block = @timeline.block_for(mod)
    @timeline.position(block) + [@timeline.modules_for(block).index(mod)]
  end

  def module_item(mod)
    kind = mod.exercise? ? 'exercise' : 'training'
    Item.new(key: "#{kind}-#{mod.slug}", kind:, title: mod.name, training_module: mod,
             due_date: @timeline.due_date_for(mod))
  end

  def article_item
    exercises = @timeline.exercise_modules.select { |mod| @timeline.article_exercise?(mod) }
    position = exercises.any? ? module_position(exercises.first) : [Float::INFINITY] * 3
    [position, Item.new(key: ARTICLE_KEY, kind: 'article', training_modules: exercises)]
  end

  # Positioned at the end of its block, or after the timeline without one.
  def peer_review_items
    return [] unless @timeline.peer_reviews_expected? ||
                     StudentProgress::PeerReviewFacts.new(@roster).any?

    block = @timeline.peer_review_block
    position = block ? @timeline.position(block) + [Float::INFINITY] : [Float::INFINITY] * 4
    [[position, Item.new(key: 'peer-review', kind: 'peer_review',
                         due_date: block&.calculated_due_date)]]
  end
end
