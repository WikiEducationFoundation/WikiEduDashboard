# frozen_string_literal: true

require 'rails_helper'

describe 'error pages' do
  # These steps are necessary to actually load the error pages in rspec.
  # See http://stackoverflow.com/questions/9008520
  before do
    method = Rails.application.method(:env_config)
    expect(Rails.application).to receive(:env_config).with(no_args) do
      method.call.merge(
        'action_dispatch.show_exceptions' => true,
        'action_dispatch.show_detailed_exceptions' => false
      )
    end
  end

  describe 'for non-existent courses' do
    it 'describes the 404 problem' do
      visit '/courses/this/course_is_not_(real)'
      expect(page).to have_content 'Page not found'
      expect(page.status_code).to eq(404)
    end
  end

  describe 'for non-existent campaigns' do
    it 'describes the 404 problem' do
      # /campaigns/not_real redirects to overview
      visit '/campaigns/not_real/overview'
      expect(page).to have_content 'Page not found'
      expect(page.status_code).to eq(404)
    end
  end

  describe 'for server errors' do
    it 'says there was a server error' do
      allow(CoursesPresenter).to receive(:new).and_raise(StandardError)
      visit '/'
      expect(page).to have_content 'internal server error'
      expect(page.status_code).to eq(500)
    end
  end

  describe 'for incorrect passcode' do
    it 'describes the passcode problem' do
      visit '/errors/incorrect_passcode'
      expect(page).to have_content 'Incorrect passcode'
      expect(page.status_code).to eq(401)
    end
  end
end
