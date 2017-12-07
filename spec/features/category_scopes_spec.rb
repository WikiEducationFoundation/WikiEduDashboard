# frozen_string_literal: true

require 'rails_helper'

describe 'Tracked categories and template', js: true do
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

  it 'lets a facilitator add and remove a category' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'
    find('#category_name').set('Photography')
    find_button('Add this category').trigger('click')
    click_button 'OK'
    expect(page).to have_content 'Category:Photography'

    # Re-add the same category
    click_button 'Add category'
    find('#category_name').set('Photography')
    find_button('Add this category').trigger('click')
    click_button 'OK'

    click_button 'Remove'
    expect(page).not_to have_content 'Photography'
  end

  it 'lets a facilitator add a template' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'
    find('#category_name').set('Stub')
    find_button('Add this template').trigger('click')
    click_button 'OK'
    expect(page).to have_content 'Template:Stub'
  end
end
