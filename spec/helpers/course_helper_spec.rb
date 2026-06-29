# frozen_string_literal: true

require 'rails_helper'

describe CourseHelper, type: :helper do
  describe '#format_course_stats' do
    it 'folds legacy "unknown" bucket into "other updates" and drops it' do
      stats = { 'www.wikidata.org' => { 'other updates' => 5, 'unknown' => 3 } }
      result = format_course_stats(stats)
      expect(result['www.wikidata.org']).to eq('other updates' => '8')
    end

    it 'tolerates "unknown" without an existing "other updates" entry' do
      stats = { 'www.wikidata.org' => { 'unknown' => 2 } }
      result = format_course_stats(stats)
      expect(result['www.wikidata.org']).to eq('other updates' => '2')
    end

    it 'does not crash when "other updates" is zero and "unknown" is absent' do
      # Regression: `if hash['other updates']` was truthy for 0 in Ruby, so
      # the helper would then read hash['unknown'] (nil) and TypeError.
      stats = { 'www.wikidata.org' => { 'other updates' => 0, 'claims created' => 7 } }
      result = format_course_stats(stats)
      expect(result['www.wikidata.org']).to eq('other updates' => '0', 'claims created' => '7')
    end

    it 'humanizes numbers per wiki/namespace key' do
      stats = { 'en.wikipedia.org-namespace-0' => { 'edits' => 12_500 } }
      result = format_course_stats(stats)
      expect(result['en.wikipedia.org-namespace-0']).to eq('edits' => '12.5K')
    end
  end

  describe '#date_highlight_class' do
    it 'returns "table-row--warning" for courses ending soon' do
      course = build(:course, start: 1.month.ago, end: 5.days.from_now)
      expect(date_highlight_class(course)).to eq('table-row--warning')
    end

    it 'returns "table-row--info" for courses that started recently' do
      course = build(:course, start: 5.days.ago, end: 1.month.from_now)
      expect(date_highlight_class(course)).to eq('table-row--info')
    end

    it 'returns empty string for other courses' do
      course = build(:course, start: 1.month.ago, end: 1.month.from_now)
      expect(date_highlight_class(course)).to eq('')
    end
  end
end
