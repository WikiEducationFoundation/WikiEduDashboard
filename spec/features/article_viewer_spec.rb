# frozen_string_literal: true

require 'rails_helper'

describe 'Article Viewer', type: :feature, js: true do
  let(:course) { create(:course, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    course.campaigns << Campaign.first
    create(:courses_user, course: course, user: user)
    create(:revision, article: article, user: user, date: '2019-01-01')
    create(:articles_course, course: course, article: article, user_ids: [user.id])
  end

  it 'shows list of students who edited the article' do
    visit "/courses/#{course.slug}/articles"
    find('button.icon-article-viewer').click
    expect(page).to have_content("Edits by: \nRagesoss")
    within(:css, '.user-legend.user-highlight-1', wait: 20) do # once authorship date loads
      find('img.user-legend-hover').click # click to scroll to next highlight
    end
  end
end
