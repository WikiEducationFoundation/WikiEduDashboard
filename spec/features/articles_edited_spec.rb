# frozen_string_literal: true

require 'rails_helper'

describe 'Articles Edited view', type: :feature, js: true do
  let(:course) { create(:course, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    course.campaigns << Campaign.first
    create(:courses_user, course: course, user: user)
    create(:revision, article: article, user: user, date: '2019-01-01')
    create(:articles_course, course: course, article: article, user_ids: [user.id])
  end

  it 'article development graphs fetch and render edit data' do
    visit "/courses/#{course.slug}/articles"
    expect(page).to have_content('Nancy Tuana')
    find('a', text: '(article development)').click
    expect(page).to have_content('Edit Size')
  end
end
