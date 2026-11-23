# frozen_string_literal: true

require 'rails_helper'

describe 'Metrics glossary', type: :feature, js: true do
  def entry(key)
    find("details##{key}", visible: :all)
  end

  it 'starts with every entry collapsed' do
    visit '/metrics'
    expect(page).to have_css('details.metrics-glossary__entry')
    expect(page).not_to have_css('details.metrics-glossary__entry[open]')
    expect(page).to have_content 'Words Added'
    expect(page).not_to have_content 'How it\'s calculated'
  end

  it 'opens an entry when its summary is clicked' do
    visit '/metrics'
    entry('words_added').find('summary').click
    expect(entry('words_added')).to match_css('[open]')
    expect(page).to have_content 'How it\'s calculated'
  end

  it 'links each number in an example to its entry' do
    visit '/metrics'
    within('.metrics-glossary__visual', match: :first) { click_link 'Total Edits' }
    expect(entry('total_edits')).to match_css('[open]')
  end

  it 'opens the entry a URL points at' do
    visit '/metrics#words_added'
    expect(entry('words_added')).to match_css('[open]')
    expect(entry('characters_added')).not_to match_css('[open]')
  end

  it 'opens an entry when a link to it is followed' do
    visit '/metrics#words_added'
    within('#words_added') { click_link 'Bytes Added' }
    expect(entry('characters_added')).to match_css('[open]')
  end

  it 'expands and collapses every entry' do
    visit '/metrics'
    click_button 'Expand all'
    expect(page).not_to have_css('details.metrics-glossary__entry:not([open])')
    click_button 'Collapse all'
    expect(page).not_to have_css('details.metrics-glossary__entry[open]')
  end
end
