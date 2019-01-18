# frozen_string_literal: true

require 'rails_helper'

describe 'course-specific edit settings', type: :feature, js: true do
  let(:user) { create(:admin) }
  let(:course) { create(:basic_course) }

  before do
    login_as(user)
    stub_oauth_edit
  end

  it 'allows toggling of multiple edit settings' do
    expect(course.assignment_edits_enabled?).to eq(true)

    visit "/courses/#{course.slug}"
    click_button 'Edit Details'
    expect(page).to have_content 'Enrollment edits enabled'
    select('no', from: 'assignment_edits_enabledToggle')
    click_button 'Save'
    sleep 1

    # By default, the BasicCourse will have all edit types
    # enabled. Here, we've changed the settings to disable
    # a single type, and left the rest alone.
    expect(course.reload.enrollment_edits_enabled?).to eq(true)
    expect(course.assignment_edits_enabled?).to eq(false)
    expect(course.wiki_course_page_enabled?).to eq(true)
  end
end
