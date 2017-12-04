# frozen_string_literal: true

require 'rails_helper'

describe 'Tracked categories', js: true do
  let(:course) { create(:course, type: 'ArticleScopedProgram') }
  let(:user) { create(:user) }
  before do
    JoinCourse.new(course: course, user: user, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as user
    stub_oauth_edit
  end

  it 'show up for ArticleScopedPrograms' do
    visit "/courses/#{course.slug}/articles"
    expect(page).to have_content 'Tracked Categories'
  end

  it 'can be added and removed by a facilitator' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'
    find('#category_name').set('Photography')
    click_button 'Add this category'
    click_button 'OK'
    expect(page).to have_content 'Photography'
    click_button 'Remove'
    expect(page).not_to have_content 'Photography'
  end
end
