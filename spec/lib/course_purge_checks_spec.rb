# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_purge_checks"

describe CoursePurgeChecks do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:course) do
    create(:course, slug: 'School/Old_(Term)', start: 2.years.ago, end: 1.year.ago)
  end
  let(:checks) { described_class.new(course) }

  it 'passes every check for an old, idle course' do
    create(:course_wiki_timeslice, course:, wiki: enwiki)
    expect(checks.results.values).to all(be true)
    expect(checks.passed?).to be true
  end

  it 'fails ended_long_ago for a course that ended within the purge window' do
    course.update(start: 2.months.ago, end: 1.month.ago)
    expect(checks.results[:ended_long_ago]).to be false
    expect(checks.passed?).to be false
  end

  it 'fails updated_long_ago for a course whose last update ended recently' do
    course.add_flag(key: 'update_logs',
                    value: { 1 => { 'start_time' => 1.month.ago.to_datetime,
                                    'end_time' => 1.month.ago.to_datetime } })
    expect(checks.results[:updated_long_ago]).to be false
  end

  it 'passes updated_long_ago for a course whose last update ended long ago' do
    course.add_flag(key: 'update_logs',
                    value: { 1 => { 'start_time' => 1.year.ago.to_datetime,
                                    'end_time' => 1.year.ago.to_datetime } })
    expect(checks.results[:updated_long_ago]).to be true
  end

  it 'fails no_update_running for a course with a recent unfinished update' do
    course.add_flag(key: 'unfinished_update_logs',
                    value: { '1' => { 'start_time' => 1.day.ago.to_datetime } })
    expect(checks.results[:no_update_running]).to be false
  end

  it 'fails no_full_update_pending for a course that needs a full update' do
    course.update(needs_update: true)
    expect(checks.results[:no_full_update_pending]).to be false
  end

  it 'fails no_timeslices_pending for a timeslice needing reaggregation' do
    create(:course_wiki_timeslice, course:, wiki: enwiki, needs_reaggregation: true)
    expect(checks.results[:no_timeslices_pending]).to be false
  end

  it 'fails no_timeslices_pending for an ACUWT row needing update' do
    create(:article_course_user_wiki_timeslice, course:, wiki: enwiki, needs_update: true,
                                                article_id: create(:article).id,
                                                user_id: create(:user).id)
    expect(checks.results[:no_timeslices_pending]).to be false
  end
end
