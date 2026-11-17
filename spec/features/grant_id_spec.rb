# frozen_string_literal: true

require 'rails_helper'

describe 'Grant ID in the course details', type: :feature, js: true do
  let(:course) { create(:basic_course) }
  let(:user) { create(:user) }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    ValidGrantId.replace_all(%w[1546-24563])
    JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as user
    stub_token_request
    stub_oauth_edit
  end

  it 'keeps the details open, with every edit, when the grant ID is rejected' do
    visit "/courses/#{course.slug}"
    click_button 'Edit Details'
    fill_in 'course-grant-id', with: '9999-99999'
    fill_in 'passcode-input-editable', with: 'newpasscode'
    click_button 'Save'

    # The error is shown on the grant ID field, which is outlined in red.
    within('.grant-id') do
      expect(page).to have_css 'input#course-grant-id.invalid'
      expect(page).to have_css 'p.red', text: '9999-99999 is not a recognized grant ID'
    end
    expect(page).not_to have_css '.notifications .notice, .notifications .notification'
    expect(page).to have_button 'Save'
    expect(page).to have_field 'course-grant-id', with: '9999-99999'
    expect(page).to have_field 'passcode-input-editable', with: 'newpasscode'
    expect(course.reload.grant_id).to be_nil

    fill_in 'course-grant-id', with: '1546-24563'
    click_button 'Save'

    expect(page).to have_button 'Edit Details'
    expect(page).to have_content '1546-24563'
    expect(course.reload.grant_id).to eq('1546-24563')
    expect(course.passcode).to eq('newpasscode')
  end
end
