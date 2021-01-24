# frozen_string_literal: true
require 'rails_helper'

describe 'Suspected Plagiarism', type: :feature, js: true do
  let(:course) { create(:course, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    course.campaigns << Campaign.first
    create(:courses_user, course: course, user: user)
    create(:revision, article: article, user: user, date: '2019-01-01')
    create(:articles_course, course: course, article: article, user_ids: [user.id])
  end

  it 'should show an empty list when there are no possible plagiarism' do
    visit "/courses/#{course.slug}/activity/plagiarism"
    within(:css, '.possible_plagiarism', wait: 20) do
      # Expect the table to have a single tr with a single td
      expect(page).to have_selector(:xpath, '//tbody/tr', count: 1)
      expect(page).to have_selector(:xpath, '//tbody/tr[1]/td', count: 1)
    end
  end

  it 'should show a list for plagiarism containing the correct links' do
    revision = create(:revision, article: article, user: user, date: '2019-01-01',
                      ithenticate_id: 1)
    visit "/courses/#{course.slug}/activity/plagiarism"
    within(:css, '.possible_plagiarism', wait: 20) do
      expect(page).to have_selector(:xpath, '//tbody/tr', count: 1)
      within(:xpath, '//tbody/tr') do
        expect(page).to have_link(revision.article.full_title, href: revision.article.url)
        expect(page).to have_link(href: revision.url)
        expect(page).to have_link('Report', href: revision.plagiarism_report_link)
      end
    end
  end
end
