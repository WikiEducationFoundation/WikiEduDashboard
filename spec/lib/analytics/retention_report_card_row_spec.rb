# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_report_card_row"

# The row's figures are covered through RetentionReportCard; this covers what
# is easier to see with a hand-built course.
describe RetentionReportCardRow do
  def course_with(word_count:, user_count:)
    instance_double(Course, retention_stats: [], user_count:, upload_count: 0, word_count:)
  end

  it 'rounds average words once, to the nearest whole word' do
    # 1105 / 11 = 100.4545…, which rounding via one decimal (100.5) would make 101.
    row = described_class.new([course_with(word_count: 1105, user_count: 11)], number: 1)
    expect(row.avg_words).to eq(100)
  end

  it 'leaves the per-participant figures blank for a course with nobody in it' do
    row = described_class.new([course_with(word_count: 0, user_count: 0)], number: 1)
    expect(row.avg_words).to be_nil
    expect(row.avg_uploads).to be_nil
  end
end
