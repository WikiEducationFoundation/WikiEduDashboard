# frozen_string_literal: true

require 'rails_helper'

describe 'difference viewer', type: :feature, js: true do
  let(:course) { create(:course, start: '2013-02-07', end: '2014-01-01') }
  let(:user) { create(:user, username: 'DSMalhotra') }

  before do
    create(:courses_user, course_id: course.id, user_id: user.id)

    # Updating course
    VCR.use_cassette 'diff_viewer/course_update' do
      UpdateCourseStats.new(course, full: true)
    end
  end

  it 'checks if renders details properly' do
    Capybara.using_wait_time 10 do
      visit "/courses/#{course.slug}/activity"

      # User has a total of 5 contributions since 7th Mar 2020
      # https://en.wikipedia.org/wiki/Special:Contributions/DSMalhotra
      expect(page).to have_css('button.icon-diff-viewer', count: 5)

      # Checking length of difference, a small portion of changed text (which in this case
      # is 'large fields', should appear only once) and a small portion of unchanged text
      # (which in this case is 'There are four sections of each class for NC to 10'),
      # which should appear two times (i.e., in both the columns of diff viewer)
      # https://en.wikipedia.org/w/index.php?diff=prev&oldid=944405819
      all('button.icon-diff-viewer')[2].click
      expect(page).to have_content('-22 Chars Added')
      expect(page).to have_content('large fields').once
      expect(page).to have_content('There are four sections of each class for NC to 10').twice
      expect(page).to have_content(format_local_datetime(Time.parse('2020-03-07T17:34:00.0000Z')))
    end
  end
end
