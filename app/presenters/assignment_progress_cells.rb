# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/assignment_pipeline"
require_dependency "#{Rails.root}/lib/student_progress/article_facts"
require_dependency "#{Rails.root}/lib/student_progress/exercise_facts"
require_dependency "#{Rails.root}/lib/student_progress/peer_review_facts"
require_dependency "#{Rails.root}/lib/student_progress/training_facts"

#= One student's cell on one Assignments-tab assignment, as a JSON-ready hash.
# Every cell has `user_id` and a coarse `state` (complete / in_progress /
# not_started) for counting and sorting, plus `overdue` when something due has
# passed without being done; the rest is whatever the Dashboard knows about
# that kind of work. Facts it doesn't record are left out rather than sent as
# nil, so the tab shows nothing instead of "unknown".
class AssignmentProgressCells
  def initialize(roster:, timeline:)
    @course = roster.course
    @timeline = timeline
    @training_facts = StudentProgress::TrainingFacts.new(roster, timeline:)
    @exercise_facts = StudentProgress::ExerciseFacts.new(roster, timeline:)
    @article_facts = StudentProgress::ArticleFacts.new(roster)
    @peer_review_facts = StudentProgress::PeerReviewFacts.new(roster)
  end

  def for(item, user)
    cell = case item.kind
           when 'training' then training(item, user)
           when 'exercise' then exercise(item, user)
           when 'article' then article(item, user)
           when 'peer_review' then peer_review(user)
           end
    overdue = cell[:overdue] || (cell[:state] != 'complete' && past?(item.due_date))
    { user_id: user.id, **cell, overdue: overdue || nil }.compact
  end

  private

  def past?(date)
    date.present? && Time.zone.today > date
  end

  def training(item, user)
    fact = @training_facts.training_for(user, item.training_module)
    state = if fact.completed? then 'complete'
            elsif fact.slide_progress then 'in_progress'
            else 'not_started'
            end
    { state:, completed_at: fact.completed_at, slide_progress: fact.slide_progress }
  end

  def exercise(item, user)
    fact = @exercise_facts.exercise_for(user, item.training_module)
    state = if fact.completed? then 'complete'
            elsif fact.in_progress? then 'in_progress'
            else 'not_started'
            end
    { state:, completed_at: fact.completed_at, sandbox_url: fact.sandbox_url,
      article_title: fact.article_title, article_url: fact.article_url }
  end

  # All the student's work on their assigned article(s) in one place: each
  # article with its pages and live contributions, and the exercises about the
  # article. Complete once every one of those exercises is done and the student
  # has edits in every assigned article; overdue while any of the exercises is.
  def article(item, user)
    exercises = item.training_modules.map { |mod| article_exercise(user, mod) }
    articles = @article_facts.articles_for(user).map { |article| article_entry(article, exercises) }
    { state: article_state(articles, exercises), overdue: exercises.any? { |e| e[:overdue] },
      articles:, exercises: }
  end

  def article_state(articles, exercises)
    return 'not_started' if articles.empty? && exercises.none? { |e| e[:completed] }

    all_done = articles.any? && exercises.all? { |e| e[:completed] } &&
               articles.all? { |a| a[:stats][:revisions].positive? }
    all_done ? 'complete' : 'in_progress'
  end

  def article_entry(article, exercises)
    { assignment_id: article.assignment_id, title: article.title, url: article.url,
      live: article.live, status: article.status, status_updated_at: article.status_updated_at,
      assigned_at: article.assigned_at, pages: pages(article).map(&:to_h),
      stats: article.stats.to_h, stages: stages(article, exercises) }.compact
  end

  # The course's pages for the article: bibliography and outline pages are a
  # classroom-course convention (see ArticleFunnel.stage_keys).
  def pages(article)
    kinds = ArticleFunnel.stage_keys(@course)
    article.pages.select { |page| kinds.include?(page.kind) }
  end

  # How far along the article is: each stage of the writing process in order
  # (the course's pages, then the live article) and whether the student has
  # reached it. A page stage counts once its page exists or the exercise for
  # it is done (the page check trails by an update cycle, and a student may
  # keep the page elsewhere); the bibliography also once the student has
  # moved past it in their own progress steps. The live article counts once
  # the student has edits in it.
  def stages(article, exercises)
    done_stages = exercises.select { |e| e[:completed] }.filter_map { |e| e[:stage] }
    page_stages = pages(article).map do |page|
      reached = page.created || done_stages.include?(page.kind) ||
                (page.kind == :bibliography && past_bibliography?(article))
      { key: page.kind, reached: }
    end
    page_stages << { key: :live, reached: article.stats.revisions.positive? }
  end

  def past_bibliography?(article)
    marked = article.statuses.index(AssignmentPipeline::AssignmentStatuses::BIBLIOGRAPHY_COMPLETE)
    marked.present? && article.statuses.index(article.status).to_i >= marked
  end

  def article_exercise(user, mod)
    fact = @exercise_facts.exercise_for(user, mod)
    { slug: mod.slug, name: mod.name, stage: @timeline.article_stage_for(mod),
      completed: fact.completed?,
      completed_at: fact.completed_at, due_date: fact.due_date,
      overdue: (!fact.completed? && past?(fact.due_date)) || nil,
      sandbox_url: fact.sandbox_url }.compact
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
