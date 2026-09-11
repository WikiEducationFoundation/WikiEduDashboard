# frozen_string_literal: true

require 'rails_helper'

describe UpdateCourseRetentionStats do
  include RetentionApiStubs

  let(:wiki) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, start: 130.days.ago, end: 100.days.ago) }
  let(:user1) { create(:user, username: 'user1') }
  let(:user2) { create(:user, username: 'user2') }
  let(:now) { Time.zone.now.change(usec: 0) }

  before do
    allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists)
    course.wikis = [wiki]
    create(:courses_user, course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
    e = course.end
    timeline = [e - 26.days, e - 21.days, e + 14.days,
                e + 70.days, e + 71.days, e + 72.days, e + 73.days, e + 74.days]
    stub_wiki(wiki, { 'user1' => timeline }, { 'user1' => 500 })
  end

  it 'stores one row per student with the computed metrics' do
    described_class.new(course, now:)
    expect(course.retention_stats.find_by(user: user1))
      .to have_attributes(sessions_during: 2, days_to_return: 14, sessions_after: 1, edits_60_90: 5,
                          prior_edit_count: 500, long_term_wikipedian: true, prior_course_count: 0,
                          computed_at: now)
    expect(course.retention_stats.find_by(user: user2))
      .to have_attributes(sessions_during: 0, days_to_return: 30, sessions_after: 0, edits_60_90: 0,
                          prior_edit_count: 0, long_term_wikipedian: false)
  end

  it 'drops the row of a student who is no longer enrolled' do
    create(:retention_stat, course:, user: create(:user, username: 'gone'))
    described_class.new(course, now:)
    expect(course.retention_stats.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
  end

  it 'replaces earlier rows rather than adding to them' do
    described_class.new(course, now: now - 1.day)
    described_class.new(course, now:)
    expect(course.retention_stats.count).to eq(2)
    expect(course.retention_stats.pluck(:computed_at).uniq).to eq([now])
  end

  it 'leaves nil the metrics whose windows have not closed' do
    described_class.new(course, now: course.end + 5.days)
    expect(course.retention_stats.find_by(user: user1))
      .to have_attributes(sessions_during: 2, days_to_return: nil, sessions_after: nil,
                          edits_60_90: nil)
  end
end
