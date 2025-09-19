# frozen_string_literal: true

require 'yaml'
require 'rails_helper'

def compare_course_wiki_timeslices(course, path)
  cw_actual = course.course_wiki_timeslices.map do |ts|
    ts.attributes.slice(
      'start', 'end',
      'character_sum', 'references_count',
      'revision_count', 'stats',
      'last_mw_rev_datetime', 'needs_update'
    )
  end

  cw_expected = YAML.load_file(Rails.root + path + 'expected_timeslices.yml')

  cw_expected.each_value do |ts|
    # Ensure dates are timezone and not strings
    ts['start'] = ts['start'].in_time_zone
    ts['end'] = ts['end'].in_time_zone
    if ts['last_mw_rev_datetime']
      ts['last_mw_rev_datetime'] =
        ts['last_mw_rev_datetime'].in_time_zone
    end
  end

  expect(cw_actual).to match_array(cw_expected.values)
end

def compare_article_course_timeslices(course, path)
  ac_actual = course.article_course_timeslices.map do |ts|
    ts.attributes.slice(
      'start', 'end', 'character_sum', 'references_count',
      'revision_count', 'new_article', 'tracked', 'first_revision', 'user_ids'
    )
  end

  ac_expected = YAML.load_file(Rails.root + path + 'expected_ac_timeslices.yml')

  ac_expected.each_value do |ts|
    # Ensure dates are timezone and not strings
    ts['start'] = ts['start'].in_time_zone
    ts['end'] = ts['end'].in_time_zone
    ts['first_revision'] = ts['first_revision'].in_time_zone
    ts['user_ids'] = [user.id]
  end

  expect(ac_actual).to match_array(ac_expected.values)
end

def compare_course_user_wiki_timeslices(course, path)
  cuw_actual = course.course_user_wiki_timeslices.map do |ts|
    ts.attributes.slice(
      'start', 'end', 'character_sum_ms', 'character_sum_us',
      'character_sum_draft', 'references_count', 'revision_count'
    )
  end

  cuw_expected = YAML.load_file(Rails.root + path + 'expected_cuw_timeslices.yml')

  cuw_expected.each_value do |ts|
    # Ensure dates are timezone and not strings
    ts['start'] = ts['start'].in_time_zone
    ts['end'] = ts['end'].in_time_zone
  end

  expect(cuw_actual).to match_array(cuw_expected.values)
end
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
      let(:path) { 'spec/support/split_timeslices/over_threshold/' }

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
        compare_course_wiki_timeslices(course, path)
        compare_article_course_timeslices(course, path)
        compare_course_user_wiki_timeslices(course, path)
      end
    end

    context 'when revisions do not exceed threshold' do
      let(:path) { 'spec/support/split_timeslices/under_threshold/' }

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
        compare_course_wiki_timeslices(course, path)
        compare_article_course_timeslices(course, path)
        compare_course_user_wiki_timeslices(course, path)
      end
    end
  end
end
