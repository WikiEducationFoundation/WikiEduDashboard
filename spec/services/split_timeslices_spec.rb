# frozen_string_literal: true

require 'yaml'
require 'rails_helper'

describe SplitTimeslices do
  let(:start) { '2025-08-26 17:00:00'.to_datetime }
  let(:end_date) { '2025-08-27 17:00:00'.to_datetime }
  # Use basic_course to not override dates
  let(:course) { create(:basic_course, start:, end: end_date) }
  let(:wiki) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:user) { create(:user, username: 'Rizall 91202') }
  let(:splitter) { described_class.new(course) }

  before do
    stub_wiki_validation
    course.wikis << wiki
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user:, role: 0)
  end

  describe '#handle' do
    context 'when revisions exceed threshold' do
      let(:path) { 'spec/support/split_timeslices/over_threshold/expected_timeslices.yml' }

      before do
        stub_const('SplitTimeslices::REVISION_THRESHOLD', 10)
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
      end

      it 'splits the timeslice recursively' do
        expect(course.course_wiki_timeslices.count).to eq(2)
        VCR.use_cassette 'split_timeslices/over_threshold' do
          dates = splitter.handle(wiki, start, end_date)
          expect(dates).to all(be_a(DateTime))
          expect(dates.size).to eq(9)
        end

        actual = course.course_wiki_timeslices.map do |ts|
          ts.attributes.slice(
            'start', 'end',
            'character_sum', 'references_count',
            'revision_count',
            'last_mw_rev_datetime', 'needs_update'
          )
        end

        expected = YAML.load_file(Rails.root + path)

        expected.each_value do |ts|
          # Ensure dates are timezone and not strings
          ts['start'] = ts['start'].in_time_zone
          ts['end'] = ts['end'].in_time_zone
          if ts['last_mw_rev_datetime']
            ts['last_mw_rev_datetime'] =
              ts['last_mw_rev_datetime'].in_time_zone
          end
        end

        expect(actual).to match_array(expected.values)
      end
    end

    context 'when revisions do not exceed threshold' do
      let(:path) { 'spec/support/split_timeslices/under_threshold/expected_timeslices.yml' }

      before do
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([wiki])
      end

      it 'does not split the timeslice' do
        expect(course.course_wiki_timeslices.count).to eq(2)
        VCR.use_cassette 'split_timeslices/under_threshold' do
          dates = splitter.handle(wiki, start, end_date)
          expect(dates).to all(be_a(DateTime))
          expect(dates.size).to eq(1)
        end

        actual = course.course_wiki_timeslices.map do |ts|
          ts.attributes.slice(
            'start', 'end',
            'character_sum', 'references_count',
            'revision_count',
            'last_mw_rev_datetime', 'needs_update'
          )
        end

        expected = YAML.load_file(Rails.root + path)

        expected.each_value do |ts|
          # Ensure dates are timezone and not strings
          ts['start'] = ts['start'].in_time_zone
          ts['end'] = ts['end'].in_time_zone
          if ts['last_mw_rev_datetime']
            ts['last_mw_rev_datetime'] =
              ts['last_mw_rev_datetime'].in_time_zone
          end
        end

        expect(actual).to match_array(expected.values)
      end
    end
  end
end
