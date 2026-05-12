require 'rails_helper'

describe 'wiki list on /usage page', type: :feature, js: true, js_error_expected: true do
  # 25 valid Wikipedia language codes — used to exercise show-all
  # (threshold is 20), top-10, search, and grouped views.
  langs = %w[
    en fr de es it nl pt ru ja zh ar pl uk sv no fi da cs hu el tr he th vi id
  ]

  before do
    # Bypass the live MediaWiki sanity check that fires on Wiki creation.
    allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists).and_return(true)

    langs.each_with_index do |lang, i|
      wiki = Wiki.get_or_create(language: lang, project: 'wikipedia')
      (i + 1).times do |j|
        Course.create!(
          title: "#{lang} Course #{j}",
          school: 'School',
          term: 'Term',
          slug: "School/#{lang}_course_#{j}",
          start: 1.month.ago,
          end: 1.month.from_now,
          home_wiki: wiki,
          passcode: 'pizza'
        )
      end
    end
    # Also include a wikidata wiki (no language), to verify the
    # "language || 'Other'" fallback doesn't blow up.
    wd = Wiki.get_or_create(language: nil, project: 'wikidata')
    Course.create!(
      title: 'Wikidata Course',
      school: 'School',
      term: 'Term',
      slug: 'School/wd_course',
      start: 1.month.ago,
      end: 1.month.from_now,
      home_wiki: wd,
      passcode: 'pizza'
    )
  end

  it 'renders 20 rows by default with a Show all button' do
    visit '/usage'
    expect(page).to have_css('.wiki-table tbody tr', count: 20)
    expect(page).to have_css('#wiki-show-all', text: 'Show all')
    expect(page).to have_text('Showing 20 of 26 wikis')
  end

  it 'expands to all rows when Show all is clicked' do
    visit '/usage'
    find('#wiki-show-all').click
    expect(page).to have_css('.wiki-table tbody tr', count: 26)
    expect(page).to have_no_css('#wiki-show-all')
  end

  it 'limits Top 10 view to 10 rows' do
    visit '/usage'
    find('.wiki-tab', text: 'Top 10').click
    expect(page).to have_css('.wiki-table tbody tr', count: 10)
  end

  it 'filters rows by domain when typing in search' do
    visit '/usage'
    fill_in 'wiki-search', with: 'th.wikipedia'
    expect(page).to have_css('.wiki-table tbody tr', count: 1)
    expect(page).to have_text('th.wikipedia.org')
    expect(page).to have_no_text('vi.wikipedia.org')
  end

  it 'shows a no-results message when search has no matches' do
    visit '/usage'
    fill_in 'wiki-search', with: 'no_such_wiki'
    expect(page).to have_text('No wikis found matching your search')
  end

  it 'groups wikis by project in the By project view' do
    visit '/usage'
    find('.wiki-tab', text: 'By project').click
    expect(page).to have_css('.wiki-group')
    expect(page).to have_text('Wikipedia')
    expect(page).to have_text('Wikidata')
  end

  it 'shows wikis without a language under "Other" in By language view' do
    visit '/usage'
    find('.wiki-tab', text: 'By language').click
    expect(page).to have_text('Other')
  end

  it 'has working anchor links to courses_by_wiki' do
    visit '/usage'
    # `id` is last in the langs list, so it has the most courses
    # and appears in the default top-20 view.
    expect(page).to have_link(href: '/courses_by_wiki/id.wikipedia.org')
  end
end
