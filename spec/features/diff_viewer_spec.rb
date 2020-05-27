# frozen_string_literal: true

require 'rails_helper'

describe 'difference viewer', type: :feature, js: true do
  let(:course) { create(:course, start: '2013-02-07', end: '2014-01-01') }
  let(:user) { create(:user, username: 'Greatgavini') }

  before do
    create(:courses_user, course_id: course.id, user_id: user.id)

    # Updating course
    VCR.use_cassette 'diff_viewer/course_update' do
      UpdateCourseStats.new(course, full: true)
    end
  end

  it 'checks if renders details properly' do
    visit "/courses/#{course.slug}/activity"

    # User has 3 contributions since 7th Feb 2013
    # https://en.wikipedia.org/wiki/Special:Contributions/Greatgavini
    expect(page).to have_css('button.icon-diff-viewer', count: 3)

    # Checking length of difference, a small portion of changed text (which in this case
    # is 'They see ash run into', should appear only once) and a small portion of unchanged text
    # (which in this case is 'Although Misty is the leader'), which should appear two
    # times (i.e., in both the columns of diff viewer)
    # https://en.wikipedia.org/w/index.php?diff=prev&oldid=554568302
    all('button.icon-diff-viewer').last.click
    expect(page).to have_content('-1299 Chars Added')
    expect(page).to have_content('They see ash run into').once
    expect(page).to have_content('Although Misty is the leader').twice
  end
end
