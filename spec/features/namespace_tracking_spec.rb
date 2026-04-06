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
    # content_namespaces returns [MAINSPACE, PAGE] for wikipedia by default
    expect(course.tracked_namespaces.count).to eq(2)

    visit "/courses/#{course.slug}"
    click_button 'Edit Details'
    expect(page).to have_content 'Tracked Namespaces'

    find('#namespace_select').click
    send_keys('userspace', :enter)
    send_keys('help', :enter)

    click_button 'Save'
    expect(page).not_to have_content 'Tracked Namespaces'

    # adding explicit namespaces means default content_namespaces aren't tracked
    expect(course.reload.tracked_namespaces.count).to eq(2)

    click_button 'Edit Details'
    expect(page).to have_content 'Tracked Namespaces'

    # Clear the React Select tags via keyboard backspace.
    # Backspace removes the last selected tag in react-select with isMulti.
    find('#namespace_select input').click
    4.times { send_keys(:backspace) }

    # Also clean the DB records scoped to this course
    course.course_wiki_namespaces.destroy_all


    click_button 'Save'
    expect(page).not_to have_content 'Tracked Namespaces'

    # back to default content_namespaces which includes MAINSPACE
    expect(course.reload.tracked_namespaces.count).to be > 0
    tracked = course.tracked_namespaces.map { |n| n[:namespace] }
    expect(tracked).to include(Article::Namespaces::MAINSPACE)
  end
end
