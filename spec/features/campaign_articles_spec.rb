# frozen_string_literal: true

require 'rails_helper'

describe 'campaign articles page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course, slug: 'course-1', school: 'University A') }
  let(:article) { create(:article, title: 'ExampleArticle') }
  let!(:articles_course) do
    create(:articles_course, course: course, article: article,
                             character_sum: 500, references_count: 5, view_count: 100)
  end
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end

  it 'shows articles edited by campaign courses' do
    visit "/campaigns/#{campaign.slug}/articles?locale=en"
    expect(page).to have_content('ExampleArticle')
  end

  it 'shows an explanation when there are too many articles' do
    allow_any_instance_of(CoursesPresenter).to receive(:too_many_articles?).and_return(true)
    visit "/campaigns/#{campaign.slug}/articles?locale=en"
    expect(page).to have_content(I18n.t('campaign.too_many_articles'))
  end

  describe 'advanced search filters' do
    let(:course2) { create(:course, slug: 'course-2', school: 'University B') }
    let(:article2) { create(:article, title: 'AnotherArticle') }
    let!(:articles_course2) do
      create(:articles_course, course: course2, article: article2,
                               character_sum: 100, references_count: 1, view_count: 10)
    end
    let!(:campaigns_course2) do
      create(:campaigns_course, campaign_id: campaign.id, course_id: course2.id)
    end

    it 'filters by title' do
      visit "/campaigns/#{campaign.slug}/articles?locale=en"
      fill_in 'title', with: 'Another'
      click_button 'Search'
      expect(page).to have_content('AnotherArticle')
      expect(page).not_to have_content('ExampleArticle')
    end

    it 'escapes SQL wildcard % in title search' do
      article_percent = create(:article, title: '100% dollars')
      create(:articles_course, course: course, article: article_percent)
      article_no_percent = create(:article, title: '100 dollars')
      create(:articles_course, course: course, article: article_no_percent)

      visit "/campaigns/#{campaign.slug}/articles?locale=en"
      fill_in 'title', with: '100%'
      click_button 'Search'
      expect(page).to have_content('100% dollars')
      expect(page).not_to have_content('100 dollars')
    end

    it 'escapes SQL wildcard _ in title search' do
      article_pizza = create(:article, title: 'Pizza')
      create(:articles_course, course: course, article: article_pizza)
      article_underscore = create(:article, title: 'P_zza')
      create(:articles_course, course: course, article: article_underscore)

      visit "/campaigns/#{campaign.slug}/articles?locale=en"
      fill_in 'title', with: 'P_zza'
      click_button 'Search'
      expect(page).to have_content('P zza')
      expect(page).not_to have_content('Pizza')
    end

    it 'filters by school' do
      visit "/campaigns/#{campaign.slug}/articles?locale=en&school[]=University+B"
      expect(page).to have_content('AnotherArticle')
      expect(page).not_to have_content('ExampleArticle')
    end

    it 'filters by character added range' do
      visit "/campaigns/#{campaign.slug}/articles?locale=en"
      find('#toggle_advanced_search').click
      fill_in 'char_added_from', with: '200'
      fill_in 'char_added_to', with: '600'
      click_button 'Search'
      expect(page).to have_content('ExampleArticle')
      expect(page).not_to have_content('AnotherArticle')
    end

    it 'filters by references range' do
      visit "/campaigns/#{campaign.slug}/articles?locale=en&references_count_from=2"
      expect(page).to have_content('ExampleArticle')
      expect(page).not_to have_content('AnotherArticle')
    end

    it 'filters by views range' do
      visit "/campaigns/#{campaign.slug}/articles?locale=en&view_count_to=50"
      expect(page).to have_content('AnotherArticle')
      expect(page).not_to have_content('ExampleArticle')
    end
  end
end
