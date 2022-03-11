# frozen_string_literal: true
require 'rails_helper'

slug = 'foo/bar'

describe 'Articles Edited view', type: :feature, js: true do
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:home_wiki) { Wiki.get_or_create language: 'en', project: 'wikipedia' }
  let(:es_wiktionary) { create(:wiki, language: 'es', project: 'wiktionary') }
  let(:fr_wikidata) { create(:wiki, language: 'fr', project: 'wikidata') }
  
  before do
    stub_wiki_validation
    course = create(:course,
      slug: slug,
      start: '2017-01-01',
      end: '2021-01-01',
      home_wiki_id: home_wiki.id
    )
    article1 = create(:article, title: 'Article 1', wiki_id: home_wiki.id)
    article2 =  create(:article, title: 'Article 2', wiki_id: es_wiktionary.id)
    article3 =  create(:article, title: 'Article 3', wiki_id: fr_wikidata.id)
    article4 =  create(:article, title: 'Article 4', wiki_id: fr_wikidata.id)
    article5 =  create(:article, title: 'Article 5', wiki_id: fr_wikidata.id)

    course.campaigns << Campaign.first
    create(:courses_user, course: course, user: user)
    create(:revision, article: article1, user: user, date: '2019-01-01')
    create(:revision, article: article2, user: user, date: '2018-01-01')
    create(:revision, article: article3, user: user, date: '2020-04-01')
    create(:revision, article: article4, user: user, date: '2020-03-01')
    create(:revision, article: article5, user: user, date: '2020-05-01')

    create(:articles_course, course: course, article: article1, user_ids: [user.id])
    create(:articles_course, course: course, article: article2, user_ids: [user.id], new_article: true)
    create(:articles_course, course: course, article: article3, user_ids: [user.id])
    create(:articles_course, course: course, article: article4, user_ids: [user.id], new_article: true)
    create(:articles_course, course: course, article: article5, user_ids: [user.id], tracked: false)
  end

  it 'article development graphs fetch and render edit data' do
    visit "/courses/#{slug}/articles"
    expect(page).to have_content('Article 1')
    find('a', text: '(article development)', match: :first).click
    expect(page).to have_content('Edit Size')
  end

  it 'wiki filter works and updates the URL' do
    visit "/courses/#{slug}/articles"
    select 'wikidata'

    expect(page).to have_content("Article 3")
    expect(page).to have_content("Article 4")

    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 2")
    expect(page).to have_no_content("Article 5")

    expect(page.current_url).to include("wiki=wikidata")
  end

  it 'newness filter works and updates the URL' do 
    visit "/courses/#{slug}/articles"
    select 'New'

    expect(page).to have_content("Article 2")
    expect(page).to have_content("Article 4")

    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 3")
    expect(page).to have_no_content("Article 5")

    expect(page.current_url).to include("newness=new")
  end

  it 'tracked filter works and updates the URL' do 
    visit "/courses/#{slug}/articles"
    select 'Untracked'

    expect(page).to have_content("Article 5")
    
    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 2")
    expect(page).to have_no_content("Article 3")
    expect(page).to have_no_content("Article 4")

    expect(page.current_url).to include("tracked=untracked")
  end

  it 'filters are set from the URL' do 
    visit "/courses/#{slug}/articles?newness=new&wiki=wikidata"

    expect(page).to have_content("Article 4")
    
    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 2")
    expect(page).to have_no_content("Article 3")
    expect(page).to have_no_content("Article 5")
  end

  it 'switching to a different tab and returning maintains filters' do 
    visit "/courses/#{slug}/articles"

    select 'Existing'
    select 'wikidata'

    expect(page).to have_content("Article 3")

    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 2")
    expect(page).to have_no_content("Article 4")
    expect(page).to have_no_content("Article 5")

    expect(page.current_url).to include("wiki=wikidata")
    expect(page.current_url).to include("newness=existing")
    
    # # go to another tab
    click_link 'Uploads'
    # # return back
    click_link 'Articles'

    expect(page).to have_content("Article 3")

    expect(page).to have_no_content("Article 1")
    expect(page).to have_no_content("Article 2")
    expect(page).to have_no_content("Article 4")
    expect(page).to have_no_content("Article 5")

    expect(page.current_url).to include("wiki=wikidata")
    expect(page.current_url).to include("newness=existing")
  end
end
