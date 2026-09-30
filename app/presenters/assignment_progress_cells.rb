# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/assignment_pipeline"
require_dependency "#{Rails.root}/lib/student_progress/article_facts"
require_dependency "#{Rails.root}/lib/student_progress/exercise_facts"
require_dependency "#{Rails.root}/lib/student_progress/peer_review_facts"
require_dependency "#{Rails.root}/lib/student_progress/training_facts"

#= One student's cell on one Assignments-tab assignment, as a JSON-ready hash.
# Every cell has `user_id` and a coarse `state` (complete / in_progress /
# not_started) for counting and sorting, plus `overdue` when the assignment
# has a due date that has passed without it being complete; the rest is
# whatever the Dashboard knows about that kind of work. Facts it doesn't
# record are left out rather than sent as nil, so the tab shows nothing
# instead of "unknown".
class AssignmentProgressCells
  def initialize(roster:, timeline:)
    @course = roster.course
    @training_facts = StudentProgress::TrainingFacts.new(roster, timeline:)
    @exercise_facts = StudentProgress::ExerciseFacts.new(roster, timeline:)
    @article_facts = StudentProgress::ArticleFacts.new(roster)
    @peer_review_facts = StudentProgress::PeerReviewFacts.new(roster)
  end

  def for(item, user)
    cell = case item.kind
           when 'training' then training(item, user)
           when 'exercise' then exercise(item, user)
           when 'article' then article_stage(item, user)
           when 'peer_review' then peer_review(user)
           end
    { user_id: user.id, **cell, overdue: overdue?(item, cell[:state]) || nil }.compact
  end

  private

  def training(item, user)
    fact = @training_facts.training_for(user, item.training_module)
    state = if fact.completed? then 'complete'
            elsif fact.slide_progress then 'in_progress'
            else 'not_started'
            end
    { state:, completed_at: fact.completed_at, slide_progress: fact.slide_progress }
  end

  # An exercise about an article stage also carries each assigned article's
  # work, since that is where the exercise's output lives.
  def exercise(item, user)
    fact = @exercise_facts.exercise_for(user, item.training_module)
    state = if fact.completed? then 'complete'
            elsif fact.in_progress? then 'in_progress'
            else 'not_started'
            end
    { state:, completed_at: fact.completed_at, sandbox_url: fact.sandbox_url,
      article_title: fact.article_title, article_url: fact.article_url,
      articles: item.article_stage ? articles(user, item.article_stage) : nil }
  end

  def overdue?(item, state)
    state != 'complete' && item.due_date.present? && Time.zone.today > item.due_date
  end

  # A student with several articles is complete once every one is.
  def article_stage(item, user)
    entries = articles(user, item.article_stage)
    done = entries.count { |entry| entry[:complete] }
    state = if entries.any? && done == entries.size then 'complete'
            elsif done.positive? then 'in_progress'
            else 'not_started'
            end
    { state:, articles: entries }
  end

  def articles(user, stage)
    @article_facts.articles_for(user).map do |article|
      { assignment_id: article.assignment_id, title: article.title, url: article.url,
        live: article.live, status: article.status,
        status_updated_at: article.status_updated_at,
        pages: article.pages.map(&:to_h), stats: article.stats.to_h,
        complete: stage_complete?(article, stage) }.compact
    end
  end

  def stage_complete?(article, stage)
    case stage
    when :selection then true
    when :bibliography then page_created?(article, :bibliography) || bibliography_marked?(article)
    when :outline, :draft then page_created?(article, stage)
    when :live then article.stats.revisions.positive?
    end
  end

  def page_created?(article, kind)
    article.pages.find { |page| page.kind == kind }&.created || false
  end

  # The student has moved past the bibliography step in the pipeline, which
  # counts even if the page check hasn't caught up (or the page lives elsewhere).
  def bibliography_marked?(article)
    marked = AssignmentPipeline::AssignmentStatuses::BIBLIOGRAPHY_COMPLETE
    index = article.statuses.index(marked)
    index.present? && article.statuses.index(article.status).to_i >= index
  end

  def peer_review(user)
    facts = @peer_review_facts.reviews_for(user)
    done = facts.completed_count
    target = facts.expected || facts.reviews.size
    state = if target.positive? && done >= target then 'complete'
            elsif done.positive? then 'in_progress'
            else 'not_started'
            end
    { state:, expected: facts.expected, completed_count: done,
      reviews: facts.reviews.map(&:to_h) }
  end
end
