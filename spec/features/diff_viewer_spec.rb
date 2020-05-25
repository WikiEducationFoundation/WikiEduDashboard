# frozen_string_literal: true

require 'rails_helper'

describe 'difference viewer', type: :feature, js: true do
  let(:course) { create(:course, start: '2013-10-01', end: '2014-10-01') }
  let(:user) { create(:user, username: '66.45.13.253') }

  it 'checks if renders details properly' do
    create(:courses_user, course_id: course.id, user_id: user.id)

    # Updating course
    login_as user
    VCR.use_cassette 'diff_viewer/course_update' do
      visit "/courses/#{course.slug}/manual_update"
    end

    # User has 6 contributions since 24th Oct 2013
    # https://en.wikipedia.org/wiki/Special:Contributions/66.45.13.253
    visit "/courses/#{course.slug}/activity"
    expect(page).to have_css('button.icon-diff-viewer', count: 6)

    # Checking length of difference, difference of characters (which in this case
    # is ' lilah', should appear only once) and a small portion of unchanged text,
    # which should appear two times (i.e., in both the columns of diff viewer)
    # https://en.wikipedia.org/w/index.php?title=Heaven%27s_Gate_(religious_group)&diff=prev&oldid=578607606
    all('button.icon-diff-viewer').last.click
    expect(page).to have_content('6 Chars Added')
    expect(page).to have_content(' lilah').once
    expect(page).to have_content('Jacques Vallée').twice
  end
end
