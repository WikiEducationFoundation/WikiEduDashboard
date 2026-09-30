# frozen_string_literal: true

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
    articles = @article_facts.articles_for(user).map { |article| article_entry(article) }
    exercises = item.training_modules.map { |mod| article_exercise(user, mod) }
    { state: article_state(articles, exercises), overdue: exercises.any? { |e| e[:overdue] },
      articles:, exercises: }
  end

  def article_state(articles, exercises)
    return 'not_started' if articles.empty? && exercises.none? { |e| e[:completed] }

    all_done = articles.any? && exercises.all? { |e| e[:completed] } &&
               articles.all? { |a| a[:stats][:revisions].positive? }
    all_done ? 'complete' : 'in_progress'
  end

  def article_entry(article)
    { assignment_id: article.assignment_id, title: article.title, url: article.url,
      live: article.live, status: article.status, status_updated_at: article.status_updated_at,
      pages: article.pages.map(&:to_h), stats: article.stats.to_h }.compact
  end

  def article_exercise(user, mod)
    fact = @exercise_facts.exercise_for(user, mod)
    { slug: mod.slug, name: mod.name, completed: fact.completed?,
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
