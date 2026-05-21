# frozen_string_literal: true

require 'rails_helper'

describe 'Assigned Articles view', type: :feature, js: true do
  let(:en_wiki) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, home_wiki: en_wiki, type: 'ClassroomProgramCourse') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana', wiki: en_wiki) }

  before do
    login_as(user)
    course.campaigns << Campaign.first
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
        puts "=== ASSIGNED ARTICLES SPEC FAILURE DIAGNOSTICS ==="
        puts "Current URL: #{page.current_url}"
        puts "Page Title: #{page.title}"
        puts "Course database attributes: #{course.attributes.slice('id', 'slug', 'type').inspect}"
        puts "Course assignments count: #{course.assignments.count}"
        if course.assignments.any?
          puts "First assignment attributes: #{course.assignments.first.attributes.inspect}"
        end

        puts "All anchors on page:"
        page.all('a', visible: :any).each do |a|
          puts "  - Text: #{a.text.inspect}, href: #{a[:href].inspect}, classes: #{a[:class].inspect}, visible: #{a.visible?}"
        end

        begin
          console_logs = page.driver.browser.logs.get(:browser)
          puts "JS Console logs:"
          console_logs.each do |log|
            puts "  [#{log.level}] #{log.message}"
          end
        rescue => log_err
          puts "  (Could not fetch browser console logs: #{log_err.message})"
        end
        puts "=================================================="
        raise e
      end
    end
  end
end

