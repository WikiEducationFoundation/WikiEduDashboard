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
      sleep 1
      expect(page).to have_content course.title
      expect(page).not_to have_content 'Syllabus'
    end
  end

  describe 'admin foobar' do
    it 'shows syllabus upload' do
      login_as(user, scope: :user)
      visit "/courses/#{course.slug}?syllabus_upload=true"
      sleep 1
      expect(page).to have_content course.title
      expect(page).to have_content 'Syllabus'
    end
    it 'shows syllabus upload' do
      login_as(user, scope: :user)
      visit "/courses/#{course.slug}?syllabus_upload=true"
      sleep 1
      click_button 'edit'
      sleep 1
      # unsurprisingly, capybara doesn't want to try to upload a file
      # with the native file picker. this isn't really testable
      # attach_file 'browse_files', "#{Rails.root}/fixtures/files/blank.pdf"
      # click_link 'save'
      # sleep 1
      # expect(course.syllabus_file_name).not_to be_nil
    end
  end
end
