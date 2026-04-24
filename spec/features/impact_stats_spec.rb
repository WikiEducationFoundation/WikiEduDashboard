# frozen_string_literal: true

require 'rails_helper'

describe 'impact stats', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before do
    Setting.set_hash('impact_stats', 'wiki_edu_courses', 100)
    Setting.set_hash('impact_stats', 'students', '5,000')
    Setting.set_hash('impact_stats', 'worked_articles', '20,000')
    Setting.set_hash('impact_stats', 'added_words', 50)
    Setting.set_hash('impact_stats', 'total_pages', '250,000')
    Setting.set_hash('impact_stats', 'volumes', 500)
    Setting.set_hash('impact_stats', 'article_views', 800)
    Setting.set_hash('impact_stats', 'universities', 500)
    Rails.cache.delete('impact_stats')
  end

  it 'updates a stat via settings and shows the  new value on the home page' do
    visit '/'
    expect(page).to have_content('500 universities')
    expect(page).to have_content('5,000')

    login_as(admin, scope: :user)
    visit '/settings'
    click_button I18n.t('settings.common_settings_components.buttons.update_impact_stats')
    expect(page).to have_field('universities', with: '500')
    expect(page).to have_field('students', with: '5,000')

    fill_in 'universities', with: '550'
    click_button I18n.t('application.submit')
    expect(page).to have_content('Impact Stats Updated Successfully.')

    logout(:user)
    visit '/'
    expect(page).to have_content('550 universities')
    expect(page).to have_content('5,000')
  end
end
