# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe 'Assignments tab', type: :feature, js: true do
  let(:course) do
    create(:course, slug: 'School/Assignments_(Fall_2026)', start: 1.month.ago,
                    end: 3.months.from_now, timeline_start: 1.month.ago,
                    timeline_end: 3.months.from_now)
  end
  let(:instructor) { create(:user, username: 'Prof') }
  let(:amy) { create(:user, username: 'Amy') }
  let(:bo) { create(:user, username: 'Bo') }
  let(:training) do
    create(:training_module, slug: 'wiki-essentials', name: 'Wikipedia essentials', kind: 0)
  end
  let(:week) { create(:week, course:, order: 0) }
  let(:course_path) { "/courses/#{course.slug}" }

  before do
    page.current_window.resize_to(1920, 1080)
    # An instructor's course page checks their wiki credentials.
    allow_any_instance_of(WikiEdits).to receive(:oauth_credentials_valid?).and_return(true)
    create(:courses_user, course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    [amy, bo].each do |user|
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    create(:block, week:, order: 0, title: 'Trainings', training_module_ids: [training.id])
    TrainingModulesUsers.create!(user: amy, training_module: training, completed_at: 1.day.ago)
    Assignment.create!(course:, user: bo, wiki: course.home_wiki,
                       role: Assignment::Roles::ASSIGNED_ROLE, article_title: 'Sea_otter')
  end

  describe 'as the instructor' do
    before { login_as(instructor) }

    it 'goes from the class summary to a roster and through students one at a time' do
      visit course_path
      within('.course_navigation') { click_link 'Assignments' }

      within('.assignments-tab__list') do
        expect(page).to have_content 'Wikipedia essentials'
        expect(page).to have_content 'Live article'
        click_link 'Wikipedia essentials'
      end

      expect(page).to have_css('tbody tr', count: 2)
      expect(find('tbody tr', text: 'Amy')).to have_content 'Completed'
      expect(find('tbody tr', text: 'Bo')).to have_content 'Not started'

      click_link 'Amy'
      expect(page).to have_css('.assignments-tab__student h4', text: 'Amy')
      expect(page).to have_content '1 / 2'
      click_button 'Next'
      expect(page).to have_css('.assignments-tab__student h4', text: 'Bo')
      expect(page).to have_current_path(%r{/assignments/training-wiki-essentials/Bo\z})
    end

    it 'shows each student\'s assigned article on an article stage' do
      visit "#{course_path}/assignments/article-selection"
      expect(find('tbody tr', text: 'Bo')).to have_link 'Sea otter'
      expect(find('tbody tr', text: 'Amy')).to have_content 'No article chosen yet'
    end
  end

  it 'has no Assignments tab for a student' do
    login_as(amy)
    visit course_path
    expect(page).to have_css('#students-link')
    expect(page).not_to have_css('#assignments-link')
  end

  it 'has no Assignments tab for a course type without it' do
    course.update!(type: 'BasicCourse')
    login_as(instructor)
    visit course_path
    expect(page).to have_css('#overview-link')
    expect(page).not_to have_css('#assignments-link')
  end
end
