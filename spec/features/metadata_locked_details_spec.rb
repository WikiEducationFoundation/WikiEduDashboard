# frozen_string_literal: true

require 'rails_helper'

describe 'Details of a course with locked metadata', type: :feature, js: true do
  let(:course) { create(:basic_course, private: true, flags: { purgeable: true }) }
  let(:user) { create(:user) }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as user
    stub_token_request
    stub_oauth_edit
    visit "/courses/#{course.slug}"
  end

  it 'keeps the fields that affect course updates read-only in edit mode' do
    click_button 'Edit Details'
    within '.course-details' do
      expect(page).to have_button 'Save'
      %w[start end timeline_start timeline_end].each do |date|
        expect(page).not_to have_css "input.#{date}"
      end
      expect(page).not_to have_css '.course_type_selector input'
      expect(page).not_to have_css '.home-wiki input'
      expect(page).not_to have_css '.multi-wiki input'
      expect(page).not_to have_css '.namespace-select input'
    end
  end

  it 'labels the read-only wikis and namespaces, defaulting to mainspace' do
    click_button 'Edit Details'
    expect(page).to have_css '.home-wiki', text: 'Home Wiki: en.wikipedia.org'
    expect(page).to have_css '.multi-wiki', text: 'Tracked Wikis: en.wikipedia.org'
    expect(page).to have_css '.namespace-select',
                             text: 'Tracked Namespaces: en.wikipedia.org - Mainspace'
  end

  it 'lets the course be made public' do
    click_button 'Edit Details'
    within '.private_selector' do
      find('input').send_keys('No', :enter)
    end
    click_button 'Save'

    expect(page).to have_button 'Edit Details'
    expect(course.reload.private).to be(false)
  end

  it 'shows the Edit Description button' do
    expect(page).to have_button 'Edit Description'
  end
end
