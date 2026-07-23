# frozen_string_literal: true

# Assembles a student's progress overview for the in-Canvas nav-item launch:
# their assigned articles (mirroring "My Articles"), rolled-up training and
# exercise completion, and the single most-urgent next step. The next step is
# the earliest-due incomplete training or exercise (by timeline due date),
# falling back to article work once those are done. Read-only; every link opens
# the Dashboard in a new tab, since the full SPA can't render in the partitioned
# Canvas iframe.
class StudentStatusContext
  ArticleRow = Struct.new(:title, :url, :role, :status_label, :sandbox_url,
                          keyword_init: true)
  ItemRow = Struct.new(:name, :done, :url, :due_date, keyword_init: true)
  NextStep = Struct.new(:label, :url, keyword_init: true)

  FAR_FUTURE = Date.new(9999, 1, 1)

  attr_reader :course, :user

  def initialize(course:, user:)
    @course = course
    @user = user
  end

  def articles
    @articles ||= assignments.map { |assignment| article_row(assignment) }
  end

  def training_items
    @training_items ||= LtiTrainingProgress.new(@course, @user).module_statuses
                                           .map { |mod, done| training_item(mod, done) }
  end

  def exercise_items
    @exercise_items ||= exercise_blocks.map { |block| exercise_item(block) }
  end

  def trainings_completed
    training_items.count(&:done)
  end

  def exercises_completed
    exercise_items.count(&:done)
  end

  # Earliest-due incomplete training/exercise; article work once those are done.
  def next_step
    return @next_step if defined?(@next_step)

    pending = (training_items + exercise_items).reject(&:done)
    soonest = pending.min_by { |item| item.due_date || FAR_FUTURE }
    @next_step = soonest ? NextStep.new(label: soonest.name, url: soonest.url) : article_next_step
  end

  private

  def assignments
    @assignments ||= @user.assignments.where(course: @course).includes(:article).to_a
  end

  def article_row(assignment)
    ArticleRow.new(title: assignment.article_title, url: assignment.article&.url,
                   role: assignment.editing? ? 'editing' : 'reviewing',
                   status_label: I18n.t("article_statuses.#{assignment.status}", default: ''),
                   sandbox_url: assignment.sandbox_url)
  end

  def training_item(mod, done)
    ItemRow.new(name: mod.name, done:, url: training_url(mod), due_date: block_due_date(mod))
  end

  def exercise_item(block)
    ItemRow.new(name: block.title, done: exercise_done?(block),
                url: exercise_url(block), due_date: block.calculated_due_date)
  end

  def exercise_blocks
    @exercise_blocks ||= @course.blocks.includes(:week).to_a
                                .select { |block| block.training_modules.any?(&:exercise?) }
                                .sort_by { |block| [block.week.order, block.order] }
  end

  def exercise_done?(block)
    LtiBlockProgress.new(block, @user, exercises_only: true).score_given >= 1.0
  end

  def exercise_url(block)
    mod = block.training_modules.detect(&:exercise?)
    return if mod.nil?
    return "/courses/#{@course.slug}/#{mod.exercise_path}" if mod.exercise_path.present?

    training_url(mod)
  end

  def training_url(mod)
    "/training/#{@course.training_library_slug}/#{mod.slug}" \
      "?return_to=#{CGI.escape("/courses/#{@course.slug}")}"
  end

  def block_due_date(mod)
    block = @course.blocks.detect { |candidate| candidate.training_module_ids.include?(mod.id) }
    block&.calculated_due_date
  end

  # Once trainings/exercises are done, the remaining work is the student's
  # article; point at the first one they're editing.
  def article_next_step
    row = articles.find { |article| article.role == 'editing' }
    return if row.nil?

    NextStep.new(label: row.title, url: row.url)
  end
end
