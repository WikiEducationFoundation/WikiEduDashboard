# frozen_string_literal: true

require 'rails_helper'

describe 'Assigned Articles view', type: :feature, js: true do
  let(:en_wiki) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, home_wiki: en_wiki, type: 'ClassroomProgramCourse') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana', wiki: en_wiki) }

  before do
    login_as(user)
    course.campaigns << (Campaign.first || create(:campaign))
    create(:courses_user, course:, user:)
    create(:assignment, article_title: 'Nancy_Tuana',
                        course:, article:,
                        user:, role: 0,
                        wiki: en_wiki)
  end

  it 'lets users submit feedback about articles' do
    # This makes a call to the LiftWing API from the server,
    # we need to use VCR to avoid getting stopped by WebMock
    VCR.use_cassette('assigned_articles_view') do
      visit "/courses/#{course.slug}/articles/assigned?locale=en"
      expect(page).to have_content('Nancy Tuana')

      begin
        # Scopes the feedback button to the specific assignment row,
        # using class selector to avoid translation mismatches.
        within 'tr.assignment', text: 'Nancy Tuana' do
          find('a.button', text: /Feedback/i).click
        end

        expect(page).to have_selector('textarea.feedback-form')
        find('textarea.feedback-form').fill_in with: 'This is a great article!'
        click_button 'Add Suggestion'

        # Scopes the delete action to the suggestions/feedback viewer modal
        within '.article-viewer.feedback' do
          find('a.button', text: /Delete/i).click
        end

        expect(page).not_to have_content('This is a great article!')
      rescue Capybara::ElementNotFound, RSpec::Expectations::ExpectationNotMetError => e
        # Output detailed diagnostics to help troubleshoot failure on CI or host machine
        diagnostic_info = []
        diagnostic_info << "=== ASSIGNED ARTICLES SPEC FAILURE DIAGNOSTICS ==="
        diagnostic_info << "Current URL: #{page.current_url}"
        diagnostic_info << "Page Title: #{page.title}"
        diagnostic_info << "Course database attributes: #{course.attributes.slice('id', 'slug', 'type').inspect}"
        diagnostic_info << "Course assignments count: #{course.assignments.count}"
        if course.assignments.any?
          diagnostic_info << "First assignment attributes: #{course.assignments.first.attributes.inspect}"
        end

        diagnostic_info << "All anchors on page:"
        page.all('a', visible: :any).each do |a|
          diagnostic_info << "  - Text: #{a.text.inspect}, href: #{a[:href].inspect}, classes: #{a[:class].inspect}, visible: #{a.visible?}"
        end

        begin
          console_logs = page.driver.browser.logs.get(:browser)
          diagnostic_info << "JS Console logs:"
          console_logs.each do |log|
            diagnostic_info << "  [#{log.level}] #{log.message}"
          end
        rescue => log_err
          diagnostic_info << "  (Could not fetch browser console logs: #{log_err.message})"
        end
        diagnostic_info << "=================================================="

        raise e.class, "#{e.message}\n\n#{diagnostic_info.join("\n")}"
      end
    end
  end
end

