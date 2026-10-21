# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_report_card"

describe RetentionReportCard do
  subject(:card) { described_class.new(campaign) }

  let(:campaign) { create(:campaign, title: 'Scholars and Scientists 2025-26', slug: 'ss_2025_26') }
  let(:instructor) { create(:user, username: 'Wkent', real_name: 'Will Kent') }
  let(:finished) do
    create(:course, type: 'FellowsCohort', slug: 'S/finished', title: 'Finished course',
                    start: 200.days.ago, end: 120.days.ago, upload_count: 10, character_sum: 10_350)
  end
  let(:in_window) do
    create(:course, type: 'FellowsCohort', slug: 'S/in_window', title: 'In window',
                    start: 100.days.ago, end: 50.days.ago, character_sum: 5175)
  end
  let(:running) do
    create(:course, type: 'FellowsCohort', slug: 'S/running', title: 'Running course',
                    start: 10.days.ago, end: 30.days.from_now, user_count: 5)
  end
  let(:classroom) do
    create(:course, slug: 'S/classroom', title: 'Classroom course', start: 200.days.ago,
                    end: 120.days.ago)
  end

  before do
    campaign.courses << [finished, in_window, running, classroom]
    create(:courses_user, course: finished, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    s1, s2, s3 = %w[s1 s2 s3].map { |name| create(:user, username: name) }
    create(:retention_stat, course: finished, user: s1, sessions_during: 3, days_to_return: 10,
                            sessions_after: 2, edits_60_90: 6, computed_at: 20.days.ago)
    create(:retention_stat, course: finished, user: s2, sessions_during: 0, days_to_return: 30,
                            sessions_after: 0, edits_60_90: 0, prior_course_count: 1,
                            computed_at: 20.days.ago)
    create(:retention_stat, course: in_window, user: s3, sessions_during: 2, days_to_return: 5,
                            sessions_after: 1, computed_at: 10.days.ago)
  end

  it 'has one numbered row per Scholars & Scientists course, oldest first' do
    expect(card.rows.map(&:title)).to eq(['Finished course', 'In window', 'Running course'])
    expect(card.rows.map(&:number)).to eq([1, 2, 3])
  end

  it 'fills every column for a course past its last checkpoint' do
    expect(card.rows[0].instructors).to eq('Will Kent')
    expect(card.rows[0]).to have_attributes(
      participants: 2, long_term_wikipedians: 0, sessions_during: 3, avg_sessions_during: 1.5,
      zero_edit_participants: 1, uploads: 10, avg_uploads: 5.0, words: 2000, avg_words: 1000,
      editors_after_course: 1, pct_active_editors_after: 100.0, avg_days_to_return: 20.0,
      avg_sessions_after: 1.0, any_survival_edits: 1, any_survival_edits_returning: 0,
      survivors: 1, survivors_returning: 0
    )
  end

  it 'leaves the survival columns blank for a course still inside that window' do
    expect(card.rows[1]).to have_attributes(participants: 1, sessions_during: 2,
                                            editors_after_course: 1, avg_days_to_return: 5.0,
                                            any_survival_edits: nil, survivors: nil)
  end

  it 'shows only the cached student count for a course not yet computed' do
    expect(card.rows[2]).to have_attributes(participants: 5, long_term_wikipedians: nil,
                                            sessions_during: nil, zero_edit_participants: nil,
                                            editors_after_course: nil, avg_words: 0)
  end

  it 'knows which checkpoints each course\'s stored rows have reached' do
    expect(card.rows[0]).to be_reached(3)
    expect(card.rows[1]).to be_reached(2)
    expect(card.rows[1]).not_to be_reached(3)
    expect(card.rows[2]).not_to be_reached(1)
  end

  it 'totals the courses, aggregating each figure over the courses that have reached it' do
    expect(card.totals).to be_total
    expect(card.totals).to have_attributes(number: nil, instructors: nil, participants: 8,
                                           uploads: 10, words: 3000, sessions_during: 5,
                                           editors_after_course: 2, survivors: 1,
                                           avg_days_to_return: 15.0)
    expect(card.totals).to be_reached(3)
  end

  it 'renders the same table as CSV, with blanks for pending figures' do
    csv = CSV.parse(card.to_csv)
    expect(csv.first.first(4)).to eq(['#', 'Course', 'Instructor', 'Participants'])
    expect(csv[1].first(4)).to eq(['1', 'Finished course', 'Will Kent', '2'])
    expect(csv[3][0..2]).to eq(['3', 'Running course', ''])
    expect(csv[3][12]).to be_nil
    expect(csv.last[1]).to eq('Total')
  end
end
