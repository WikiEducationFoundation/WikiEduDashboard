# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/peer_review_facts"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

# The assignments the course page's Assignments tab tracks for a course, in
# the order it lists them:
#
# - one per training module and one per exercise module on the timeline, in
#   timeline order (discussion modules are not tracked);
# - the peer-review stage, at its timeline block, when the course expects
#   reviews or anyone has been assigned one;
# - one per stage of article work that no exercise on the timeline already
#   covers, after everything else. An exercise about an article stage (the
#   bibliography exercise, choosing an article) *is* that stage's assignment,
#   so listing the stage again would show the same work twice.
class BuildAssignmentCatalog
  # `key` is stable across requests and safe in a URL path segment.
  # `title` is the module's own name; the tab labels the other kinds itself.
  Item = Struct.new(:key, :kind, :title, :training_module, :article_stage, :due_date,
                    keyword_init: true)

  attr_reader :items

  def initialize(roster:, timeline:)
    @roster = roster
    @course = roster.course
    @timeline = timeline
    @items = build
  end

  private

  def build
    (module_items + peer_review_items).sort_by(&:first).map(&:last) + article_items
  end

  def module_items
    (@timeline.training_modules + @timeline.exercise_modules).map do |mod|
      block = @timeline.block_for(mod)
      [@timeline.position(block) + [@timeline.modules_for(block).index(mod)], module_item(mod)]
    end
  end

  def module_item(mod)
    kind = mod.exercise? ? 'exercise' : 'training'
    Item.new(key: "#{kind}-#{mod.slug}", kind:, title: mod.name, training_module: mod,
             article_stage: mod.exercise? ? @timeline.article_stage_for(mod) : nil,
             due_date: @timeline.due_date_for(mod))
  end

  # Positioned at the end of its block, or after the timeline without one.
  def peer_review_items
    return [] unless @timeline.peer_reviews_expected? ||
                     StudentProgress::PeerReviewFacts.new(@roster).any?

    block = @timeline.peer_review_block
    position = block ? @timeline.position(block) + [Float::INFINITY] : [Float::INFINITY] * 3
    [[position, Item.new(key: 'peer-review', kind: 'peer_review',
                         due_date: block&.calculated_due_date)]]
  end

  def article_items
    covered = @timeline.exercise_modules.filter_map { |mod| @timeline.article_stage_for(mod) }
    (article_stages - covered).map do |stage|
      Item.new(key: "article-#{stage}", kind: 'article', article_stage: stage)
    end
  end

  # Bibliography and outline pages are a classroom-program convention (the
  # Students tab links them only there); a no-sandboxes course has no draft.
  def article_stages
    stages = [:selection]
    stages += %i[bibliography outline] if @course.is_a?(ClassroomProgramCourse)
    stages << :draft unless @course.no_sandboxes?
    stages << :live
  end
end
