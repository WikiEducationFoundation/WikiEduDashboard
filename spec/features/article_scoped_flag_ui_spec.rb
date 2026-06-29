# frozen_string_literal: true

require 'rails_helper'

describe 'article_scoped flag UI behavior', js: true do
  let(:user) { create(:user) }

  before { stub_oauth_edit; login_as user }

  context 'BasicCourse with flags[:article_scoped] = true' do
    let(:course) do
      create(:basic_course, start: '2024-01-01', end: '2024-12-31',
                            flags: { article_scoped: true })
    end

    before { JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'shows the Tracked Categories section on the Articles page' do
      visit "/courses/#{course.slug}/articles"
      expect(page).to have_content 'Tracked Categories'
    end

    it 'shows the article scoped program info message in the statistics modal' do
      visit "/courses/#{course.slug}"
      click_button 'See more'
      expect(page).to have_content 'Article Scoped Program'
    end
  end

  context 'ArticleScopedProgram course (scoped by type)' do
    let(:course) do
      create(:article_scoped_program, start: '2024-01-01', end: '2024-12-31')
    end

    before { JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'shows the Tracked Categories section on the Articles page' do
      visit "/courses/#{course.slug}/articles"
      expect(page).to have_content 'Tracked Categories'
    end
  end

  context 'plain BasicCourse (no article_scoped flag)' do
    let(:course) { create(:basic_course, start: '2024-01-01', end: '2024-12-31') }

    before { JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'does not show the Tracked Categories section' do
      visit "/courses/#{course.slug}/articles"
      expect(page).not_to have_content 'Tracked Categories'
    end
  end

  context 'VisitingScholarship course (internally scoped but no article-scoped UI)' do
    let(:course) do
      create(:visiting_scholarship, start: '2024-01-01', end: '2024-12-31')
    end

    before { JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'does not show the Tracked Categories section' do
      visit "/courses/#{course.slug}/articles"
      expect(page).not_to have_content 'Tracked Categories'
    end

    it 'does not show the article scoped program info message in the statistics modal' do
      visit "/courses/#{course.slug}"
      # The statistics update modal info text references 'Article Scoped Program'
      # which is factually wrong for a VisitingScholarship
      click_button 'See more'
      expect(page).to have_content 'Missing or unexpected results?'
      expect(page).not_to have_content 'Article Scoped Program'
    end
  end
end
