# frozen_string_literal: true

require 'rails_helper'

describe 'FAQs', type: :feature, js: true do
  let!(:faq) { create(:faq, title: 'How does this work?', content: 'It works.') }
  let(:admin) { create(:admin) }

  before do
    FaqTopic.update(slug: 'top', name: 'Top questions', faqs: [])
    login_as admin
  end

  describe 'INDEX page' do
    it 'has search working search' do
      visit '/faq'
      fill_in 'faq_search', with: 'how does'
      click_button 'submit_search'
      expect(page).to have_content 'How does this work?'
      click_link 'Top questions'
      expect(page).not_to have_content 'How does this work?'
      click_link 'All questions'
      expect(page).to have_content 'How does this work?'
    end
  end

  describe 'SHOW page' do
    it 'includes title and content' do
      visit "/faq/#{faq.id}"
      expect(page).to have_content 'How does this work?'
      expect(page).to have_content 'It works'
    end
  end

  describe 'EDIT page' do
    it 'redirects to SHOW page after saving' do
      visit "/faq/#{faq.id}/edit"
      fill_in 'faq_content', with: 'It just works'
      click_button 'Update Faq'
      expect(page).to have_current_path("/faq/#{faq.id}")
      expect(page).to have_content 'It just works'
    end

    it 'redirects to FAQ INDEX after deleting' do
      visit "/faq/#{faq.id}/edit"
      accept_confirm do
        click_button 'Delete'
      end
      expect(page).to have_current_path('/faq')
      expect(Faq.count).to eq(0)
    end
  end

  describe 'NEW page' do
    it 'redirects to SHOW after creating' do
      visit '/faq/new'
      fill_in 'faq_title', with: 'new question'
      fill_in 'faq_content', with: 'new answer'
      click_button 'Create Faq'
      expect(page).not_to have_content 'Add new FAQ'
      expect(page).to have_content 'Let us know'
      expect(Faq.count).to eq(2)
      expect(page).to have_current_path("/faq/#{Faq.last.id}")
    end
  end
end
