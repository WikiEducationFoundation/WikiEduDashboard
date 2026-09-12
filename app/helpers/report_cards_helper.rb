# frozen_string_literal: true

module ReportCardsHelper
  # A numeric report card cell: the row's figure for the column, formatted per
  # the column; the "pending" marker when the figure has not been computed yet;
  # the not-applicable marker when it has been reached but there was nobody to
  # count, so it never will be.
  def report_card_cell(row, column)
    value = row.public_send(column.key)
    return empty_report_card_cell(row, column) if value.nil?

    case column.format
    when :integer then number_with_delimiter(value)
    when :decimal then number_with_precision(value, precision: 1)
    when :percent then "#{number_with_precision(value, precision: 1)}%"
    else value
    end
  end

  private

  def empty_report_card_cell(row, column)
    if row.reached?(column.stage)
      tag.span(t('report_cards.not_applicable'), class: 'report-card__not-applicable')
    else
      tag.span(t('report_cards.pending'), class: 'report-card__pending')
    end
  end
end
