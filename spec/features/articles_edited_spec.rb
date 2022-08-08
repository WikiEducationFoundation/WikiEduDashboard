# frozen_string_literal: true
require 'rails_helper'

slug = 'foo/bar'

describe 'Articles Edited view', type: :feature, js: true do
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:home_wiki) { Wiki.get_or_create language: 'en', project: 'wikipedia' }
  let(:es_wiktionary) { create(:wiki, language: 'es', project: 'wiktionary') }
  let(:wikidata) { create(:wiki, project: 'wikidata') }

  before do
    stub_wiki_validation

    course = create(
      :course,
      slug:,
      start: '2017-01-01',
      end: '2021-01-01',
      home_wiki:
    )

    article_en_wiki = create(
      :article,
      title: 'Article en.wiki',
      wiki: home_wiki
    )
    new_article_es_wiktionary = create(
      :article,
      title: 'Article new es.wiktionary',
      wiki: es_wiktionary
    )
    article_wikidata = create(
      :article,
      title: 'Article wikidata',
      wiki: wikidata
    )
    new_article_wikidata = create(
      :article,
      title: 'Article new wikidata',
      wiki: wikidata
    )
    untracked_article_wikidata = create(
      :article,
      title: 'Article untracked wikidata',
      wiki: wikidata
    )

    course.campaigns << Campaign.first
    create(:courses_user, course:, user:)
    create(:revision, article: article_en_wiki, user:, date: '2019-01-01')
    create(:revision, article: new_article_es_wiktionary, user:, date: '2018-01-01')
    create(:revision, article: article_wikidata, user:, date: '2020-04-01')
    create(:revision, article: new_article_wikidata, user:, date: '2020-03-01')
    create(:revision, article: untracked_article_wikidata, user:, date: '2020-05-01')

    create(
      :articles_course,
      course:,
      article: article_en_wiki,
      user_ids: [user.id]
    )
    create(
      :articles_course,
      course:,
      article: new_article_es_wiktionary,
      user_ids: [user.id],
      new_article: true
    )
    create(
      :articles_course,
      course:,
      article: article_wikidata,
      user_ids: [user.id]
    )
    create(
      :articles_course,
      course:,
      article: new_article_wikidata,
      user_ids: [user.id],
      new_article: true
    )

    create(
      :articles_course,
      course:,
      article: untracked_article_wikidata,
      user_ids: [user.id],
      tracked: false
    )
  end

  it 'article development graphs fetch and render edit data' do
    visit "/courses/#{slug}/articles"
    expect(page).to have_content('Article en.wiki')
    find('a', text: '(article development)', match: :first).click
    expect(page).to have_content('Edit Size')
  end

  it 'wiki filter works and updates the URL' do
    visit "/courses/#{slug}/articles"
    select 'wikidata'

    expect(page).to have_content('Article wikidata')
    expect(page).to have_content('Article new wikidata')

    expect(page).to have_no_content('Article untracked wikidata')
    expect(page).to have_no_content('Article new es.wiktionary')
    expect(page).to have_no_content('Article en.wiki')

    expect(page.current_url).to include('wiki=wikidata')
  end

  it 'newness filter works and updates the URL' do
    visit "/courses/#{slug}/articles"
    select 'New'

    expect(page).to have_content('Article new es.wiktionary')
    expect(page).to have_content('Article new wikidata')

    expect(page).to have_no_content('Article en.wiki')
    expect(page).to have_no_content('Article wikidata')
    expect(page).to have_no_content('Article untracked wikidata')

    expect(page.current_url).to include('newness=new')
  end

  it 'tracked filter works and updates the URL' do
    visit "/courses/#{slug}/articles"
    select 'Untracked'

    expect(page).to have_content('Article untracked wikidata')

    expect(page).to have_no_content('Article en.wiki')
    expect(page).to have_no_content('Article new es.wiktionary')
    expect(page).to have_no_content('Article wikidata')
    expect(page).to have_no_content('Article new wikidata')

    expect(page.current_url).to include('tracked=untracked')
  end

  it 'filters are set from the URL' do
    visit "/courses/#{slug}/articles?newness=new&wiki=wikidata"

    expect(page).to have_content('Article new wikidata')

    expect(page).to have_no_content('Article en.wiki')
    expect(page).to have_no_content('Article new es.wiktionary')
    expect(page).to have_no_content('Article untracked wikidata')
    expect(page).to have_no_content('Article wikidata')
  end

  it 'switching to a different tab and returning maintains filters' do
    visit "/courses/#{slug}/articles"

    select 'Existing'
    select 'wikidata'

    expect(page).to have_content('Article wikidata')

    expect(page).to have_no_content('Article en.wiki')
    expect(page).to have_no_content('Article new es.wiktionary')
    expect(page).to have_no_content('Article untracked wikidata')
    expect(page).to have_no_content('Article new wikidata')

    expect(page.current_url).to include('wiki=wikidata')
    expect(page.current_url).to include('newness=existing')

    # # go to another tab
    click_link 'Uploads'
    # # return back
    click_link 'Articles'

    expect(page).to have_content('Article wikidata')

    expect(page).to have_no_content('Article en.wiki')
    expect(page).to have_no_content('Article new es.wiktionary')
    expect(page).to have_no_content('Article untracked wikidata')
    expect(page).to have_no_content('Article new wikidata')

    expect(page.current_url).to include('wiki=wikidata')
    expect(page.current_url).to include('newness=existing')
  end
end
