# frozen_string_literal: true

module ReportCardsHelper
  # A numeric report card cell: formatted per the column, or the "pending"
  # marker when the figure is not available yet.
  def report_card_cell(value, format)
    return tag.span(t('report_cards.pending'), class: 'report-card__pending') if value.nil?

    case format
    when :integer then number_with_delimiter(value)
    when :decimal then number_with_precision(value, precision: 1)
    when :percent then "#{number_with_precision(value, precision: 1)}%"
    else value
    end
  end
end
