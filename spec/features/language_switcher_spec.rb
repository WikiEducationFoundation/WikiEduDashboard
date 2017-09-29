# frozen_string_literal: true

require 'rails_helper'

describe 'language_switcher', type: :feature, js: true do
  context 'user logged out' do
    it 'should default to English' do
      visit root_path
      expect(page).to have_css('.uls-trigger', text: 'en')
    end

    it 'should switch to another language using URL param' do
      visit root_path
      click_button('en')
      expect(page).to have_text('Common languages')
      expect(page).to have_text('français')
      find("#uls-lcd-quicklist li[title='français'] > a").click
      expect(page.current_path).to eq root_path
      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq(root_path(locale: 'fr'))
      expect(page).to have_text('Se connecter avec Wikipédia')
    end
  end

  context 'user logged in' do
    before(:each) do
      @user = create(:user)
      login_as(@user, scope: :user)
    end

    it 'should default to English' do
      visit root_path
      expect(page).to have_css('.uls-trigger', text: 'en')
    end

    it 'should switch to another language using user model' do
      visit root_path
      click_button('en')
      expect(page).to have_text('Common languages')
      expect(page).to have_text('français')
      find("#uls-lcd-quicklist li[title='français'] > a").click
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
