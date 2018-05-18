# frozen_string_literal: true
require 'rails_helper'

describe 'language_switcher', type: :feature, js: true do
  before { allow(Features).to receive(:enable_language_switcher?).and_return(true) }

  context 'user logged out' do
    it 'should default to English' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        expect(page).to have_css('.Select-placeholder', text: 'en')
      end
    end

    it 'should switch to another language using URL param' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        find('.Select').click
        expect(page).to have_css('.Select-menu-outer')
        expect(page).to have_text('Français')
        find('.Select-option', text: 'Français').click
      end
      expect(page.current_path).to eq root_path
      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq(root_path(locale: 'fr'))
      expect(page).to have_text('Se connecter avec Wikipédia')
    end
  end

  context 'user logged in' do
    before(:each) do
      page.driver.restart if defined?(page.driver.restart)
      @user = create(:user)
      login_as(@user, scope: :user)
      page.current_window.resize_to(3000, 1080) # Workaround for PhantomJS layout bug
    end

    it 'should default to English' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        expect(page).to have_css('.Select-placeholder', text: 'en')
      end
    end

    it 'should switch to another language using user model' do
      visit root_path
      expect(page).to have_css('.language-picker')
      within('.language-picker') do
        expect(page).to have_css('.Select')
        find('.Select').click
        expect(page).to have_css('.Select-menu-outer')
        expect(page).to have_text('Help translate')
        expect(page).to have_text('Français')
        find('.Select-option', text: 'Français').click
      end
      expect(page.current_path).to eq root_path
      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq("#{root_path}?")
      expect(page).to have_text('Mon tableau de bord')
      expect(@user.reload.locale).to eq('fr')
    end

    it 'should use URL parameter first, if set' do
      @user.locale = 'fr'
      @user.save
      visit root_path(locale: 'en')
      expect(page).to have_text('My Dashboard')
    end
  end
end
