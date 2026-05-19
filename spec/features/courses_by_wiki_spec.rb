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
    expect(page).to be_axe_clean
  end

  it 'handles wikis with no courses' do
    visit '/courses_by_wiki/www.wikidata.org'
    expect(page).to have_content 'www.wikidata.org'
    expect(page).to be_axe_clean
  end
end

describe 'active courses page', type: :feature, js: true do
  it 'loads cleanly' do
    visit '/active_courses'
    expect(page).to have_content 'Active Courses'
    expect(page).to be_axe_clean
  end
end

describe 'unsubmitted courses page', type: :feature, js: true do
  before do
    stub_wiki_validation
    create(:course, title: 'Draft course', submitted: false)
    login_as(create(:admin))
  end

  it 'loads cleanly' do
    visit '/unsubmitted_courses'
    expect(page).to have_content 'Draft course'
    expect(page).to be_axe_clean
  end
end
