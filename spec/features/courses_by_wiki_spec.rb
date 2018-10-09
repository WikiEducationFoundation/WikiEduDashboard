# frozen_string_literal: true

require 'rails_helper'

describe 'courses by wiki page', type: :feature, js: true do
  before do
    stub_wiki_validation
    create(:course, title: 'The only course')
  end

  it 'includes courses for requested wiki' do
    visit '/courses_by_wiki/en.wikipedia.org'
    expect(page).to have_content 'The only course'
  end

  it 'handles wikis with no courses' do
    visit '/courses_by_wiki/www.wikidata.org'
    expect(page).to have_content 'www.wikidata.org'
  end
end
