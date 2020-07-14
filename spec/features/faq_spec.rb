# frozen_string_literal: true

require 'rails_helper'

describe 'FAQs', type: :feature, js: true do
  let!(:faq) { create(:faq, title: 'How does this work?', content: 'It works.') }
  let(:admin) { create(:admin) }

  before { login_as admin }

  describe 'INDEX page' do
    it 'has search working search' do
      visit '/faq'
      fill_in 'faq_search', with: 'how does'
      click_button 'submit_search'
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
      click_button 'delete'
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
      expect(Faq.count).to eq(2)
      expect(page).to have_current_path("/faq/#{Faq.last.id}")
      expect(page).to have_content 'new answer'
    end
  end
end
