# frozen_string_literal: true

require 'csv'

#= The course page Assignments tab's data as a CSV, one row per student (in
# the tab's username order). For each tracked assignment: its status
# (complete / in_progress / not_started) and whether it's overdue, plus the
# main details of its kind:
#
# - trainings and exercises: when the student completed it;
# - the assigned article: the student's articles and which stages of the
#   writing process they've reached (the exercises about the article have
#   their own columns, as exercises);
# - peer reviews: how many the student has done.
#
# Assignments come in the tab's order: the assigned article, then trainings,
# exercises and peer reviews, each in timeline order.
class AssignmentProgressCsvBuilder
  KIND_ORDER = %w[article training exercise peer_review].freeze

  def initialize(presenter, real_names:)
    @presenter = presenter
    @real_names = real_names
  end

  def generate_csv
    CSV.generate do |csv|
      csv << student_headers + columns.map(&:first)
      @presenter.students.each_with_index do |user, index|
        csv << student_values(user) + columns.map { |_, item, value| value.call(cell(item, index)) }
      end
    end
  end

  private

  def student_headers
    @real_names ? %w[username real_name] : %w[username]
  end

  def student_values(user)
    @real_names ? [user.username, user.real_name] : [user.username]
  end

  # Every column after the student's: [header, item, value-from-cell].
  def columns
    @columns ||= items.flat_map do |item|
      fields(item).map { |field, value| ["#{label(item)}: #{field}", item, value] }
    end
  end

  def items
    by_kind = @presenter.items.group_by(&:kind)
    KIND_ORDER.flat_map { |kind| by_kind.fetch(kind, []) }
  end

  # Rows come one cell per student, in student order.
  def cell(item, index)
    @presenter.rows_for(item)[index]
  end

  def label(item)
    return item.title if item.title
    return I18n.t('lti.status.roster.peer_reviews') if item.kind == 'peer_review'
    I18n.t('lti.assignment_view.roster.assigned_article')
  end

  # [field, value-from-cell] pairs: status and overdue, then by kind.
  def fields(item)
    [['status', ->(cell) { cell[:state] }],
     ['overdue', ->(cell) { cell[:overdue].present? }]] + kind_fields(item)
  end

  def kind_fields(item)
    case item.kind
    when 'training', 'exercise' then [['completed_at', ->(cell) { cell[:completed_at] }]]
    when 'article' then article_fields
    when 'peer_review' then [['reviews_completed', ->(cell) { cell[:completed_count] }]]
    end
  end

  # Having an article at all is the articles column, so the stages start
  # after that one.
  def article_fields
    stages = ArticleFunnel.stage_keys(@presenter.course) - [:assigned]
    [['articles', ->(cell) { cell[:articles].pluck(:title).join('; ').presence }]] +
      stages.map { |key| ["#{key}_reached", ->(cell) { ArticleFunnel.reached?(cell, key) }] }
  end
end
