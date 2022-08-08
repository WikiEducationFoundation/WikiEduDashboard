# frozen_string_literal: true
require 'rails_helper'

describe 'Suspected Plagiarism', type: :feature, js: true do
  let(:course) { create(:course, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    course.campaigns << Campaign.first
    create(:courses_user, course:, user:)
    create(:revision, article:, user:, date: '2019-01-01')
    create(:articles_course, course:, article:, user_ids: [user.id])
  end

  context 'when there are no revisions suspected of plagiarism' do
    it 'should show a no suspected plagiarism text' do
      no_revision = 'There are not currently any recent revisions suspected of plagiarism.'
      visit "/courses/#{course.slug}/activity/plagiarism"
      expect(page).to have_content no_revision
    end
  end

  context 'when there are revisions suspected of plagiarism' do
    let(:revision) do
      create(:revision, article:, user:, date: '2019-01-01', ithenticate_id: 1)
    end

    context 'when logged in as a student' do
      before do
        login_as(user)
        stub_oauth_edit
      end

      it 'should show a list for plagiarism without the link to plagiarism report' do
        visit "/courses/#{course.slug}/activity/plagiarism"
        expect(page).to have_link(revision.article.full_title, href: revision.article.url)
        expect(page).to have_link(href: revision.url)
        expect(page).to have_no_link('Report', href: revision.plagiarism_report_link)
      end
    end

    context 'when logged in as an admin' do
      let(:admin) { create(:admin) }

      before do
        login_as(admin)
        stub_oauth_edit
      end

      it 'should show a list for plagiarism containing the correct links' do
        visit "/courses/#{course.slug}/activity/plagiarism"
        expect(page).to have_link(revision.article.full_title, href: revision.article.url)
        expect(page).to have_link(href: revision.url)
        expect(page).to have_link('Report', href: revision.plagiarism_report_link)
      end
    end
  end
end
