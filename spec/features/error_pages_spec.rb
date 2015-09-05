require 'rails_helper'

describe 'error pages' do
  # These steps are necessary to actually load the error pages in rspec.
  # See http://stackoverflow.com/questions/9008520
  before do
    Rails.application.config.consider_all_requests_local = false
    Rails.application.config.action_dispatch.show_exceptions = true
    load 'application_controller.rb'
  end

  describe 'for non-existent courses' do
    it 'should describe the 404 problem' do
      visit '/courses/this/course_is_not_(real)'
      expect(page).to have_content 'Page not found'
    end
  end

  describe 'for non-existent cohorts' do
    it 'should describe the 404 problem' do
      visit '/courses?cohort=not_real'
      expect(page).to have_content 'Page not found'
    end
  end

  after do
    Rails.application.config.consider_all_requests_local = true
    Rails.application.config.action_dispatch.show_exceptions = false
    load 'application_controller.rb'
  end
end
