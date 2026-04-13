# frozen_string_literal: true

require 'rails_helper'

describe 'campaign programs search', type: :feature, js: true do
  let(:campaign) { create(:campaign) }
  let(:admin) { create(:admin) }

  let!(:course1) do
    create(:course, title: 'Biology 101',
                    slug: 'State_University/Biology_101_(Fall_2024)',
                    school: 'State University',
                    term: 'Fall 2024',
                    user_count: 25,
                    character_sum: 15000,
                    references_count: 100,
                    view_sum: 500,
                    recent_revision_count: 50)
  end

  let!(:course2) do
    create(:course, title: 'Computer Science 201',
                    slug: 'Tech_Institute/Computer_Science_201_(Spring_2024)',
                    school: 'Tech Institute',
                    term: 'Spring 2024',
                    user_count: 15,
                    character_sum: 8000,
                    references_count: 45,
                    view_sum: 200,
                    recent_revision_count: 30)
  end

  let!(:course3) do
    create(:course, title: 'History of Art',
                    slug: 'Arts_College/History_of_Art_(Winter_2024)',
                    school: 'Arts College',
                    term: 'Winter 2024',
                    user_count: 10,
                    character_sum: 3000,
                    references_count: 20,
                    view_sum: 100,
                    recent_revision_count: 10)
  end

  before do
    create(:campaigns_course, campaign:, course: course1)
    create(:campaigns_course, campaign:, course: course2)
    create(:campaigns_course, campaign:, course: course3)
  end

  describe 'search form' do
    before do
      admin.locale = 'en'
      admin.save!
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
    end

    it 'displays the search form' do
      expect(page).to have_css('#campaign_search_form')
      expect(page).to have_field('title_query')
    end

    it 'searches by course title' do
      fill_in 'title_query', with: 'Biology'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('Computer Science')
    end

    it 'searches by school name' do
      fill_in 'title_query', with: 'State University'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
    end

    it 'searches by term' do
      fill_in 'title_query', with: 'Fall 2024'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
    end

    it 'displays search results count' do
      fill_in 'title_query', with: '101'
      click_button I18n.t('campaign.search')
      expect(page).to have_content(I18n.t('application.search_results.one',
        search_terms: 'title: 101', count: 1))
    end
  end

  describe 'advanced search toggle' do
    before do
      admin.locale = 'en'
      admin.save!
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
    end

    it 'hides advanced search by default' do
      expect(page).to have_selector('#advanced_search_fields.hidden', visible: :all)
    end

    it 'toggles advanced search fields' do
      click_button 'toggle_advanced_search'
      expect(page).not_to have_selector('#advanced_search_fields.hidden', visible: :all)
      click_button 'toggle_advanced_search'
      expect(page).to have_selector('#advanced_search_fields.hidden', visible: :all)
    end
  end

  describe 'advanced search filters' do
    before do
      admin.locale = 'en'
      admin.save!
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
      click_button 'toggle_advanced_search'
    end

    it 'filters by revisions range' do
      fill_in 'revisions_min', with: '40'
      fill_in 'revisions_max', with: '60'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('Computer Science')
    end

    it 'filters by word count range' do
      fill_in 'word_count_min', with: '2000'
      fill_in 'word_count_max', with: '5000'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('History of Art')
    end

    it 'filters by references range' do
      fill_in 'references_min', with: '50'
      fill_in 'references_max', with: '150'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('History of Art')
    end

    it 'filters by views range' do
      fill_in 'views_min', with: '300'
      fill_in 'views_max', with: '600'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('History of Art')
    end

    it 'filters by editors range' do
      fill_in 'users_min', with: '20'
      fill_in 'users_max', with: '30'
      click_button I18n.t('campaign.search')
      expect(page).to have_content('Biology 101')
      expect(page).not_to have_content('History of Art')
    end

    it 'clears all filters' do
      fill_in 'title_query', with: 'Biology'
      fill_in 'revisions_min', with: '40'
      fill_in 'revisions_max', with: '60'
      click_button 'clear_filters'
      expect(page).to have_content('Biology 101')
      expect(page).to have_content('Computer Science')
      expect(page).to have_content('History of Art')
      expect(current_url).not_to include('title_query')
    end
  end

  describe 'table sorting' do
    before do
      admin.locale = 'en'
      admin.save!
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
    end

    it 'sorts by title ascending and descending' do
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Biology 101'
      find('#courses [data-sort="title"].sort').click
      expect(page).to have_selector('#courses [data-sort="title"].sort.asc')
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Biology 101'
      find('#courses [data-sort="title"].sort').click
      expect(page).to have_selector('#courses [data-sort="title"].sort.desc')
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'History of Art'
    end

    it 'sorts by school' do
      find('#courses [data-sort="school"].sort').click
      expect(page).to have_selector('#courses [data-sort="school"].sort.asc')
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Arts College'
      find('#courses [data-sort="school"].sort').click
      expect(page).to have_selector('#courses [data-sort="school"].sort.desc')
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Tech Institute'
    end

    it 'sorts by revisions' do
      expect(page).to have_selector('[data-sort="revisions"].sort.desc')
      find('#courses [data-sort="revisions"].sort').click
      expect(page).to have_selector('[data-sort="revisions"].sort.asc')
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'History of Art'
    end
  end

  describe 'sort and search combination' do
    before do
      admin.locale = 'en'
      admin.save!
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
    end

    it 'maintains sort when searching' do
      find('#courses [data-sort="title"].sort').click
      expect(page).to have_selector('#courses [data-sort="title"].sort.asc')

      fill_in 'title_query', with: 'Art'
      click_button I18n.t('campaign.search')

      expect(page).to have_selector('#courses [data-sort="title"].sort.asc')
      expect(page).to have_content('History of Art')
    end
  end
end
