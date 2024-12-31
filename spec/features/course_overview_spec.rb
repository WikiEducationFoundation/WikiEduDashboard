# frozen_string_literal: true

require 'rails_helper'

describe 'course overview page', type: :feature, js: true do
  let(:slug)         { 'This_university.foo/This.course_(term_2015)' }
  let(:course_start) { '2015-02-11'.to_date }
  let(:course_end)   { course_start + 6.months }
  let(:course) do
    create(:course,
           id: 10001,
           title: 'This.course',
           slug:,
           start: course_start.to_date,
           end: course_end.to_date,
           timeline_start: course_start.to_date,
           timeline_end: course_end.to_date,
           school: 'This university.foo',
           term: 'term 2015',
           description: 'This is a great course',
           weekdays: '1001001')
  end
  let(:campaign) { create(:campaign) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
  end
  let(:week) { create(:week, course_id: course.id) }
  let(:content) { 'Edit Wikipedia' }
  let!(:block)  { create(:block, week_id: week.id, content:) }
  let(:admin)   { create(:admin) }

  before do
    stub_token_request
    login_as(admin, scope: :user)
  end

  context 'when course has started' do
    before do
      visit "/courses/#{course.slug}"
      sleep 1
    end

    it 'displays week activity for this week' do
      find '.course__this-week' do
        expect(page).to have_content 'This Week'
      end
    end
  end

  context 'when course starts in future' do
    let(:course_start) { '2025-02-11'.to_date }
    let(:course_end) { course_start + 6.months }
    let(:timeline_start) { '2025-02-11'.to_date + 2.weeks }
    let(:timeline_end) { course_end.to_date }

    before do
      course.update(timeline_start:)
      visit "/courses/#{course.slug}"
      sleep 1
    end

    it 'displays week activity for the first week' do
      within '.course__this-week' do
        expect(page).to have_content('First Active Week')
        expect(page).to have_content content
      end
      within '.week-range' do
        expect(page).to have_content(timeline_start.beginning_of_week(:sunday).strftime('%m/%d'))
      end
      within '.margin-bottom' do
        meeting_dates = [
          Date.parse('2025-02-23'),  # Sunday (02/23)
          Date.parse('2025-02-26'),  # Wednesday (02/26)
          Date.parse('2025-03-01')   # Saturday (03/01)
        ]

        meeting_dates.each do |meeting_date| # rubocop:disable RSpec/IteratedExpectation
          expect(meeting_date)
            .to be_between(timeline_start, timeline_end)
            .or be_between(course_start, course_end)
        end

        expect(page).to have_content('Meetings: Wednesday (02/26), Saturday (03/01)')
      end
      within '.week-index' do
        expect(page).to have_content(/Week \d+/)
      end
    end
  end
end
