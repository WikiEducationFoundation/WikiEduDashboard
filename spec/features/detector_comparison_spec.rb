# frozen_string_literal: true

require 'rails_helper'

describe 'AI detector comparison page', type: :feature, js: true do
  include_context 'detector comparison data'

  let(:admin) { create(:admin) }
  let(:generated_cell) { "a[aria-label^='GPT-6 Astra, Assignment, Glacial stream']" }

  # The site scrolls smoothly, so wait for the element to arrive just below the fixed navbar.
  def scrolled_to?(id)
    50.times.any? do
      sleep 0.1
      top = page.evaluate_script("document.getElementById('#{id}').getBoundingClientRect().top")
      (60..140).cover?(top)
    end
  end

  describe 'as an admin' do
    before { login_as(admin) }

    it 'shows the default selection and lets the grid be filtered' do
      visit '/detector_comparison/topics'
      expect(page).to have_css 'h1', text: 'Texts on 16 topics'
      within '.detector-comparison__topic-grid' do
        expect(page).to have_content 'Glacial stream'
        expect(page).to have_content 'Average, all topics'
        expect(page).to have_content "Article after the student's term"
        expect(page).to have_content 'Agpedia article'
        expect(page).to have_content 'Average across current models'
        expect(page).not_to have_content 'GPT-6 Astra'
        expect(page).to have_link 'Glacial stream',
                                  href: '/detector_comparison/topics/Glacial%20stream'
      end
      average_row = find('tr', text: 'Assignment', match: :first)
      average_row.find('.detector-comparison__cell span', match: :first).hover
      expect(page).to have_css '.detector-comparison__tooltip', text: '1 texts'
      find('summary', text: 'Change what the table shows').click
      check 'GPT-6 Astra'
      check 'Originality AI Allowance 15'
      within('.detector-comparison__topic-grid') { expect(page).to have_content 'Assignment' }
      find(generated_cell).hover
      within '.detector-comparison__tooltip' do
        expect(page).to have_content '0.990 · AI'
        expect(page).to have_content 'not scored'
      end
      all('tr', text: 'Assignment').last.find('.detector-comparison__cell--average').hover
      expect(page).to have_css '.detector-comparison__tooltip', text: 'flagged'
      expect(page).to have_current_path(/models=/)
    end

    it 'sends a table selection made before the datasets had pages to the 16-topic table' do
      selection = 'models=gpt-6-astra&strategies=assignment'
      visit "/detector_comparison?#{selection}"
      expect(page).to have_current_path("/detector_comparison/topics?#{selection}")
      expect(page).to have_css generated_cell
    end

    it 'opens a text from its cell' do
      visit '/detector_comparison/topics?models=gpt-6-astra&strategies=assignment'
      find(generated_cell).click

      expect(page).to have_content 'GPT-6 Astra · Assignment · Glacial stream'
      expect(page).to have_content 'Detector results'
      expect(page).to have_content 'The call failed: HTTP 402'
      expect(page).to have_content(/research only/i)
      expect(page).to have_css 'mark.detector-comparison__window', count: 2
      expect(page).to have_link '[the article as it stood before the student’s term]'
      expect(page).to have_link 'Every text on Glacial stream'
    end

    it "shows each strategy's prompts with a topic placeholder" do
      visit '/detector_comparison/topics'
      find('summary', text: 'The prompts (3 turns').click
      expect(page).to have_content 'Assigned article: [topic]'
      expect(page).to have_content '[the article as it stood before the student’s term]'
    end

    it "opens a conclusion's table from anywhere on its card and shows it above the table" do
      visit '/detector_comparison'
      title = first('.detector-comparison__view-button').text
      first('.detector-comparison__view-cue').click
      expect(page).to have_current_path(%r{/detector_comparison/topics\?.*detectors=})
      within('.detector-comparison__active-view') { expect(page).to have_content title }
      click_link 'All conclusions'
      expect(page).to have_current_path('/detector_comparison')
      expect(scrolled_to?('detector-comparison-conclusions')).to be(true)
    end

    it 'opens a false-positive conclusion on the known-human table' do
      visit '/detector_comparison'
      find('.detector-comparison__view', text: /show in the known-human table/i).click
      expect(page).to have_current_path(%r{/detector_comparison/known_human\?})
      expect(page).to have_css '.detector-comparison__active-view'
      expect(page).to have_css 'th', text: 'Open Pangram (RoBERTa)'
    end

    it 'lists the known-human texts with each detector and switches to the other dataset' do
      visit '/detector_comparison'
      click_link 'Known human writing'
      expect(page).to have_css 'h1', text: 'Known human writing'
      within('.detector-comparison__baseline-summary') do
        expect(page).to have_css 'tr', text: 'Pangram 4'
        expect(page).to have_content '97.50%'
      end
      click_link "Text #{human.id}"
      expect(page).to have_content "Student's additions: Glacial stream"
      click_link 'Every known-human text'
      click_link '16 topics'
      expect(page).to have_css 'h1', text: 'Texts on 16 topics'
    end

    it 'links the AI-written explanations to their authorship note' do
      visit '/detector_comparison/topics'
      find("h2 a[href='#detector-comparison-authorship']", text: '†').click
      expect(page).to have_css '#detector-comparison-authorship',
                               text: 'from "How to read this page" to the end of the page'
    end

    it 'follows a link in a view description to a section of the explanations' do
      content = Rails.root.join('tmp/detector_comparison_feature_spec.yml')
      File.write(content, <<~YAML)
        views:
          - key: one
            title: First view
            description: See [the ladder](/detector_comparison/topics#open-weight-ladder).
            selection: { detectors: [a40], topics: all }
      YAML
      stub_const('RenderDetectorComparisonIntro::CONTENT_PATH', content)
      visit '/detector_comparison'
      click_link 'the ladder'
      expect(page).to have_current_path('/detector_comparison/topics')
      expect(scrolled_to?('open-weight-ladder')).to be(true)
    ensure
      FileUtils.rm_f(content)
    end

    it 'shows every text on a topic' do
      visit '/detector_comparison/topics/Glacial%20stream'
      expect(page).to have_css 'h1', text: 'Glacial stream'
      expect(page).to have_link "Student's additions"
      expect(page).to have_link "Article after the student's term"
      expect(page).to have_link 'Agpedia article'
      expect(page).to have_css "a[aria-label^='GPT-6 Astra, Assignment']"
    end

    it 'opens the paired student text' do
      visit "/detector_comparison/units/#{human.id}"
      expect(page).to have_content "Student's additions: Glacial stream"
    end
  end

  describe 'as a non-admin' do
    before { login_as(create(:user)) }

    it 'is not authorized' do
      visit '/detector_comparison'
      expect(page).not_to have_content 'AI detector comparison'
    end
  end
end
