# frozen_string_literal: true

require 'rails_helper'

describe 'Namespace tracking', type: :feature, js: true do
  let(:course) { create(:basic_course) }
  let(:user) { create(:user) }

  before do
    JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as user
    stub_token_request
    stub_oauth_edit
  end

  it 'lets you add or remove namespaces' do
    # mainspace is tracked by default
    expect(course.tracked_namespaces.count).to eq(1)

    visit "/courses/#{course.slug}"
    click_button 'Edit Details'
    expect(page).to have_content 'Tracked Namespaces'

    find('#namespace_select').click
    send_keys('userspace', :enter)
    send_keys('help', :enter)

    click_button 'Save'
    expect(page).not_to have_content 'Tracked Namespaces'

    # adding explicit namespaces means default mainspace isn't tracked
    expect(course.reload.tracked_namespaces.count).to eq(2)

    click_button 'Edit Details'
    expect(page).to have_content 'Tracked Namespaces'

    # Now we remove them again
    within('#namespace_select') do
      first('svg').click
      first('svg').click
    end

    click_button 'Save'
    expect(page).not_to have_content 'Tracked Namespaces'

    # back to default of just mainspace
    expect(course.reload.tracked_namespaces.count).to eq(1)
    expect(course.tracked_namespaces.first[:namespace]).to eq(Article::Namespaces::MAINSPACE)
  end
end
