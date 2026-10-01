# frozen_string_literal: true

#= The Assignments tab's headline for the assigned article: for each stage of
# the writing process, how many students have reached it. A student counts once
# any of their articles reaches a stage.
#
# Stages: having an article, then its bibliography and outline (classroom
# courses; the Students tab links them only there), the draft sandbox (unless
# the course has students edit live), and edits in the live article. A stage
# with an exercise on the timeline (choosing the article, the bibliography or
# outline exercise) takes that exercise's due date, and past it the students
# who haven't reached the stage are overdue.
class ArticleFunnel
  EXERCISE_STAGES = { selection: :assigned, bibliography: :bibliography, outline: :outline }.freeze

  def initialize(course:, item:, cells:, timeline:)
    @course = course
    @item = item
    @cells = cells
    @timeline = timeline
  end

  def to_h
    { total: @cells.size, stages: stage_keys.map { |key| stage(key) } }
  end

  def self.stage_keys(course)
    keys = [:assigned]
    keys += %i[bibliography outline] if course.is_a?(ClassroomProgramCourse)
    keys << :draft unless course.no_sandboxes?
    keys << :live
  end

  def self.reached?(cell, key)
    return cell[:articles].any? if key == :assigned

    cell[:articles].any? do |article|
      article[:stages].any? { |stage| stage[:key] == key && stage[:reached] }
    end
  end

  private

  def stage_keys
    self.class.stage_keys(@course)
  end

  def stage(key)
    reached = @cells.count { |cell| self.class.reached?(cell, key) }
    due_date = due_dates[key]
    overdue = due_date && Time.zone.today > due_date ? @cells.size - reached : nil
    { key:, reached:, due_date:, overdue: }.compact
  end

  def due_dates
    @due_dates ||= @item.training_modules.each_with_object({}) do |mod, dates|
      key = EXERCISE_STAGES[@timeline.article_stage_for(mod)]
      dates[key] ||= @timeline.due_date_for(mod) if key
    end
  end
end
