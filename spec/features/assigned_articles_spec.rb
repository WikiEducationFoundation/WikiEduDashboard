# frozen_string_literal: true

require 'rails_helper'

describe 'Assigned Articles view', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    login_as(user)
    course.campaigns << Campaign.first
    create(:courses_user, course:, user:)
    create(:assignment, article_title: 'Nancy_Tuana',
                        course:, article:,
                        user:)
  end

  it 'lets users submit feedback about articles' do
    pending 'This often breaks in CI due to an unexpected WikiApi response'
    # This makes a call to the LiftWing API from the server,
    # we need to use VCR to avoid getting stopped by WebMock
    VCR.use_cassette('assigned_articles_view') do
      visit "/courses/#{course.slug}/articles/assigned"
      expect(page).to have_content('Nancy Tuana')
      expect(page).to have_selector('a', text: 'Feedback')
      find('a', text: 'Feedback').click
      if page.has_content?("The Item doesn't exist.")
        skip 'Skipping test: feedback form not shown because LiftWing API data is unavailable'
      end
      expect(page).to have_selector('textarea.feedback-form', wait: 10)
      find('textarea.feedback-form').fill_in with: 'This is a great article!'
      click_button 'Add Suggestion'
      find('a', text: 'Delete').click
      expect(page).not_to have_content('This is a great article!')
    end

    pass_pending_spec
  end
end
