# frozen_string_literal: true

require 'rails_helper'

describe 'tagged courses pages', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }
  let(:article) { create(:article, title: 'TestArticle') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    create(:tag, course:, tag: 'test_tag')
    create(:articles_course, article:, course:)
    create(:alert, course:, type: 'BadWorkAlert')
  end

  it 'show list of courses with the tag' do
    visit '/tagged_courses/test_tag/programs'
    expect(page).to have_content(course.title)
  end

  it 'show list of articles for courses with the tag' do
    visit '/tagged_courses/test_tag/articles'
    expect(page).to have_content(article.title)
  end

  it 'show list of alerts for courses with the tag' do
    visit '/tagged_courses/test_tag/alerts'
    expect(page).to have_content('BadWorkAlert')
  end
end
