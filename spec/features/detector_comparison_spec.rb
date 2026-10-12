# frozen_string_literal: true

require 'rails_helper'

describe 'AI detector comparison page', type: :feature, js: true do
  include_context 'detector comparison data'

  let(:admin) { create(:admin) }

  describe 'as an admin' do
    before { login_as(admin) }

    it 'shows results by sample and the model-by-condition grid' do
      visit '/detector_comparison'
      expect(page).to have_content 'AI detector comparison'
      expect(page).to have_content 'Pre-ChatGPT student texts (baseline)'
      expect(page).to have_content 'Stratified conditions'
      within '.detector-comparison__grid' do
        expect(page).to have_content 'GPT-6 Astra'
        expect(page).to have_content 'Assignment'
        click_button '0%'
      end
      expect(page).to have_link 'Glacial stream'
    end

    it 'switches the grid to a detector and a topic, and opens a text' do
      visit '/detector_comparison'
      select 'Originality AI Allowance 40', from: 'Detector'
      within('.detector-comparison__grid') { expect(page).to have_content '100%' }
      select 'Glacial stream', from: 'Topic'
      expect(page).to have_link 'Student text (pre-ChatGPT)'
      click_link "#{generated.word_count} words"

      expect(page).to have_content 'GPT-6 Astra · Assignment · Glacial stream'
      expect(page).to have_content 'Detector results'
      expect(page).to have_content 'The call failed: HTTP 402'
      expect(page).to have_content(/research only/i)
      expect(page).to have_css 'mark.detector-comparison__window', count: 2
      expect(page).to have_link '[the article as it stood before the student’s term]'
      expect(page).to have_content 'Other versions of Glacial stream'
    end

    it 'opens the paired student text' do
      visit "/detector_comparison/units/#{human.id}"
      expect(page).to have_content 'Student text: Glacial stream'
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
