# frozen_string_literal: true
require 'rails_helper'

describe 'language_switcher', type: :feature, js: true do
  before { allow(Features).to receive(:enable_language_switcher?).and_return(true) }

  context 'user logged out' do
    it 'defaults to English' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        expect(page).to have_css('.language-picker__placeholder', text: 'en')
      end
    end

    it 'switches to another language using URL param' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        find('.language-picker__control').click
        expect(page).to have_css('.language-picker__menu')
        expect(page).to have_text('Français')
        find('.language-picker__option', text: 'Français').click
      end
      expect(page).to have_current_path(root_path(locale: 'fr'))
      expect(page).to have_text('Se connecter à Wikipédia')
    end

    it 'fallbacks to en for locales with incomplete translations' do
      visit root_path(locale: 'az')
      expect(page).to have_current_path(root_path(locale: 'az'))
      expect(page).to have_text('Daxil ol')
      expect(page).to have_text('Kömək')

      # az.application.training is missing so it should fallback to en
      expect(page).to have_no_content('[missing "az.')
      expect(page).to have_content('Training')
    end
  end

  context 'user logged in' do
    before do
      page.driver.restart if defined?(page.driver.restart)
      @user = create(:user)
      login_as(@user, scope: :user)
      page.current_window.resize_to(3000, 1080) # Workaround for PhantomJS layout bug
    end

    it 'defaults to English' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        expect(page).to have_css('.language-picker__placeholder', text: 'en')
      end
    end

    it 'switches to another language using user model' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        find('.language-picker__control').click
        expect(page).to have_css('.language-picker__menu')
        expect(page).to have_text('Help translate')
        expect(page).to have_text('Français')
        find('.language-picker__option', text: 'Français').click
      end
      expect(page).to have_current_path(root_path)
      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq("#{root_path}?")
      expect(page).to have_text('Mon tableau de bord')
      expect(@user.reload.locale).to eq('fr')
    end

    it 'uses URL parameter first, if set' do
      @user.locale = 'fr'
      @user.save
      visit root_path(locale: 'en')
      expect(page).to have_text('My Dashboard')
    end
  end
end
