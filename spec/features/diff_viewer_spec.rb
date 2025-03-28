# frozen_string_literal: true

require 'rails_helper'

describe 'difference viewer', type: :feature, js: true do
  let(:course) { create(:course, start: '2013-02-07', end: '2014-01-01') }
  let(:user) { create(:user, username: 'Sage (Wiki Ed)') }

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

      expect(page).to have_css('button.icon-diff-viewer')
    end
  end
end
