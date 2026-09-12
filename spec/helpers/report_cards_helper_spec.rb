# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_report_card"

describe ReportCardsHelper, type: :helper do
  describe '#report_card_cell' do
    let(:column) { RetentionReportCard::COLUMNS.find { |c| c.key == :pct_active_editors_after } }

    def row_with(value, reached:)
      instance_double(RetentionReportCardRow, pct_active_editors_after: value, reached?: reached)
    end

    it 'formats a figure per the column' do
      expect(report_card_cell(row_with(66.666, reached: true), column)).to eq('66.7%')
    end

    it 'marks a figure the row has not reached yet as pending' do
      cell = report_card_cell(row_with(nil, reached: false), column)
      expect(cell).to have_css('span.report-card__pending', text: 'pending')
    end

    it 'marks a figure the row has reached but has nobody to count as not applicable' do
      cell = report_card_cell(row_with(nil, reached: true), column)
      expect(cell).to have_css('span.report-card__not-applicable', text: '—')
    end
  end
end
