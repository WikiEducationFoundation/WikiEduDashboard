# frozen_string_literal: true

require 'rails_helper'

describe 'A Wikidata course', type: :feature, js: true do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:course) { create(:course, home_wiki: wikidata) }

  before { stub_wiki_validation }

  it 'has an Items tab instead of Articles tab' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'Items'
    expect(page).not_to have_content 'Articles'
  end
end
