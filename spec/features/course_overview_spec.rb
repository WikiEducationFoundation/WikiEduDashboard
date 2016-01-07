require 'rails_helper'

describe 'course overview page', type: :feature, js: true do
  let(:slug)         { 'This_university.foo/This.course_(term_2015)' }
  let(:course_start) { Date.today }
  let(:course_end)   { 6.months.from_now.to_date }
  let(:course) do
    create(:course,
           id: 10001,
           title: 'This.course',
           slug: slug,
           start: course_start.to_date,
           end: course_end.to_date,
           timeline_start: course_start.to_date,
           timeline_end: course_end.to_date,
           school: 'This university.foo',
           term: 'term 2015',
           listed: 1,
           description: 'This is a great course',
           weekdays: '0001000')
  end
  let(:cohort) { create(:cohort) }
  let!(:cohorts_course) { create(:cohorts_course, cohort_id: cohort.id, course_id: course.id) }
  let(:week) { create(:week, course_id: course.id) }
  let(:content) { 'Edit Wikipedia' }
  let!(:block)  { create(:block, week_id: week.id, content: content) }
  let(:admin)   { create(:admin) }

  before :each do
    stub_token_request
    login_as(admin, scope: :user)
  end

  context 'course started' do
    before do
      visit "/courses/#{course.slug}"
      sleep 1
    end
    it 'displays week activity for this week' do
      find '.course__this-week' do
        expect(page).to have_content 'This Week'
        expect(page).to have_content content
      end
    end
  end

  context 'course starts in future' do
    before do
      course.update_attribute(:timeline_start, 2.weeks.from_now.to_date)
      visit "/courses/#{course.slug}"
      sleep 1
    end
    it 'displays week activity for the first week' do
      within '.course__this-week' do
        expect(page).to have_content("First Week (#{2.weeks.from_now.strftime('%m/%d')}")
        expect(page).to have_content content
      end
      within '.week__week-dates' do
        expect(page).to have_content(2.weeks.from_now.beginning_of_week(:sunday).strftime('%m/%d'))
        expect(page).to have_content('(W)')
      end
      within '.week-index' do
        expect(page).to have_content 'Week 1'
      end
    end
  end
end
