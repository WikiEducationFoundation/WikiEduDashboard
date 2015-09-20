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

    create(:cohort)
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      page.driver.allow_url 'cdn.ravenjs.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
  end

  describe 'for unsupported browsers' do
    it 'should describe the browser problem' do
      visit '/unsupported_browser'
      expect(page).to have_content 'Unsupported browser'
      expect(page.status_code).to eq(403)
    end
  end

  describe 'for non-existent courses' do
    it 'should describe the 404 problem' do
      visit '/courses/this/course_is_not_(real)'
      expect(page).to have_content 'Page not found'
      expect(page.status_code).to eq(404)
    end
  end

  describe 'for non-existent cohorts' do
    it 'should describe the 404 problem' do
      visit '/courses?cohort=not_real'
      expect(page).to have_content 'Page not found'
    end
  end

  describe 'for server errors' do
    it 'should say there was a server error' do
      allow(HomePagePresenter).to receive(:new).and_raise(StandardError)
      visit '/'
      expect(page).to have_content 'internal server error'
      expect(page.status_code).to eq(500)
    end
  end
end
