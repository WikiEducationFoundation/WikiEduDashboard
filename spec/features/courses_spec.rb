# frozen_string_literal: true
require 'rails_helper'

campaign_course_count = 10

module ResetLocale
  RSpec.configuration.before do
    I18n.locale = 'en'
  end
end

describe 'the explore page', type: :feature do
  before do
    campaign = Campaign.first
    campaign_two = create(:campaign_two)

    (1..campaign_course_count).each do |i|
      course1 = create(:course,
                       id: i,
                       title: "course #{i}",
                       slug: "school/course_#{i}_(term)",
                       start: '2014-01-01'.to_date,
                       end: Time.zone.today + 2.days)
      course1.campaigns << campaign
      course2 = create(:course,
                       id: (i + campaign_course_count),
                       title: "course #{i + campaign_course_count}",
                       slug: "school/course_#{i + campaign_course_count}_(term)",
                       start: '2014-01-01'.to_date,
                       end: Time.zone.today + 2.days)
      course2.campaigns << campaign_two

      # STUDENTS, one per course
      create(:user, id: i, trained: true)
      create(:courses_user,
             id: i,
             course_id: i,
             user_id: i,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      # INSTRUCTORS, one per course
      create(:user, id: i + campaign_course_count, trained: true)
      create(:courses_user,
             id: i + campaign_course_count,
             course_id: i,
             user_id: i + campaign_course_count,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      # The instructors are also enrolled as students.
      create(:courses_user,
             id: i + campaign_course_count * 2,
             course_id: i,
             user_id: i + campaign_course_count,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      article = create(:article,
                       id: i,
                       title: 'Selfie',
                       namespace: 0)
      create(:articles_course,
             course_id: course1.id,
             article_id: article.id)
      create(:revision,
             id: i,
             user_id: i,
             article_id: i,
             date: 6.days.ago,
             characters: 9000)
    end
    Course.update_all_caches
  end

  describe 'header' do
    it 'should display stats accurately' do
      visit '/explore'

      # Number of courses
      course_count = Campaign.first.courses.count
      stat_text = "#{course_count} #{I18n.t('courses.course_description')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Number of students
      # one non-instructor student per course
      student_count = campaign_course_count
      stat_text = "#{student_count} #{I18n.t('courses.students')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Words added
      word_count = WordCount.from_characters Course.all.sum(:character_sum)
      stat_text = "#{word_count} #{I18n.t('metrics.word_count')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Views
      view_count = Course.all.sum(:view_sum)
      stat_text = "#{view_count} #{I18n.t('metrics.view_count_description')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Recent revisions
      expect(page.find('#courses .table tbody tr:first-child .revisions').text).to eq('1')
    end
  end

  describe 'control bar' do
    it 'should allow sorting via dropdown and loading of campaigns', js: true do
      visit '/explore'

      # sorting via dropdown
      find('select.sorts').find(:xpath, 'option[2]').select_option
      expect(page).to have_selector('[data-sort="revisions"].sort.desc')
      find('select.sorts').find(:xpath, 'option[3]').select_option
      expect(page).to have_selector('[data-sort="characters"].sort.desc')
      find('select.sorts').find(:xpath, 'option[5]').select_option
      expect(page).to have_selector('[data-sort="views"].sort.desc')
      find('select.sorts').find(:xpath, 'option[6]').select_option
      expect(page).to have_selector('[data-sort="students"].sort.desc')
      find('select.sorts').find(:xpath, 'option[1]').select_option
      expect(page).to have_selector('[data-sort="title"].sort.asc')

      # loading a different campaign
      expect(page).to have_content(Campaign.first.title)
      find('select.campaigns').find(:xpath, 'option[2]').select_option
      expect(page).to have_content(Campaign.last.title)
    end
  end

  describe 'course list' do
    it 'should be sortable', js: true do
      visit '/explore'

      # Sortable by title
      expect(page).to have_selector('[data-sort="title"].sort.asc')
      find('[data-sort="title"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="title"].sort.desc')

      # Sortable by character count
      find('[data-sort="characters"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="characters"].sort.desc')
      find('[data-sort="characters"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="characters"].sort.asc')

      # Sortable by view count
      find('[data-sort="views"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="views"].sort.desc')
      find('[data-sort="views"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="views"].sort.asc')

      # Sortable by student count
      find('[data-sort="students"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="students"].sort.desc')
      find('[data-sort="students"].sort').trigger('click')
      expect(page).to have_selector('[data-sort="students"].sort.asc')
    end
  end

  describe 'course rows' do
    it 'should allow navigation to a course page', js: true do
      visit '/explore'
      find('#courses .table tbody tr:first-child').click
      expect(current_path).to eq("/courses/#{Course.first.slug}")
    end
  end

  describe 'campaign pages' do
    it 'should load courses from the right campaign' do
      # load courses from a different campaign
      visit "/explore?campaign=#{Campaign.last.slug}"
      last_course = Campaign.last.courses.last
      expect(page).to have_content last_course.title
    end
  end

  describe 'non-default locales' do
    include ResetLocale

    it 'should switch languages' do
      visit '/explore?locale=qqq'
      expect(page.find('header')).to have_content 'Long label for the number'
    end

    it 'falls back when locale is not available' do
      visit '/explore?locale=aa'
      expect(page.find('header')).to have_content '10 Students'
    end

=begin
# TODO: Test somewhere that has access to the request.
    it 'gets preferred language from header' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'es-MX,fr'
      get ':index'
      expect(response).to have_content '10 Estudiantes'
    end
=end
  end
end
