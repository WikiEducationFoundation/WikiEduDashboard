# frozen_string_literal: true

require 'rails_helper'

describe 'syllabus upload', type: :feature, js: true do
  let(:trained)    { 1 }
  let(:course)     { create(:course) }
  let(:user)       { create(:admin) }

  before do
    include type: :feature
    include Devise::TestHelpers
    page.current_window.resize_to(1920, 1080)
    stub_oauth_edit
  end

  describe 'non-admin' do
    it 'does not show to syllabus upload' do
      visit "/courses/#{course.slug}?syllabus_upload=true"
      expect(page).to have_content course.title
      expect(page).not_to have_content 'Syllabus'
    end
  end

  describe 'for admins' do
    it 'shows syllabus upload' do
      login_as(user, scope: :user)
      visit "/courses/#{course.slug}?syllabus_upload=true"
      expect(page).to have_content course.title
      expect(page).to have_content 'Syllabus'
      click_button 'edit'
      find('input[type="file"]', visible: false)
        .attach_file Rails.root.join('spec/fixtures/files/syllabus.pdf'), make_visible: true
      click_link 'save'
      expect(page).not_to have_content 'Syllabus'
      expect(course.reload.syllabus_file_name).to eq('syllabus.pdf')
    end
  end
end
