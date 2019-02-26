# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/services/update_course_stats"
require "#{Rails.root}/lib/assignment_manager"

MILESTONE_BLOCK_KIND = 2

# Wait one second after loading a path
# Allows React to properly load the page
# Remove this after implementing server-side rendering
def js_visit(path, count=3)
  visit path
  expect(page).to have_content('Explore').or have_content('Find Programs')

# This is a workaround for some of the intermittent errors that occur when
# running capybara with xvfb, which we do on travis-ci and in vagrant.
rescue ActionController::RoutingError => e
  raise e if count < 1
  count -= 1
  js_visit(path, count)
end

user_count = 10
article_count = 19
revision_count = 214
# Dots in course titles will cause errors if routes.rb is misconfigured.
slug = 'This_university.foo/This.course_(term_2015)'
course_start = '2015-01-01'
course_end = '2015-12-31'

describe 'the course page', type: :feature, js: true do
  let(:es_wiktionary) { create(:wiki, language: 'es', project: 'wiktionary') }
  let(:home_wiki) { Wiki.get_or_create language: 'en', project: 'wikipedia' }
  let(:admin) { create(:admin) }

  before do
    stub_wiki_validation
    page.current_window.resize_to(1920, 1080)

    course = create(:course,
                    id: 10001,
                    title: 'This.course',
                    slug: slug,
                    start: course_start.to_date,
                    end: course_end.to_date,
                    timeline_start: course_start.to_date,
                    timeline_end: course_end.to_date,
                    school: 'This university.foo',
                    term: 'term 2015',
                    home_wiki_id: home_wiki.id,
                    description: 'This is a great course')
    campaign = create(:campaign)
    course.campaigns << campaign

    (1..user_count).each do |i|
      create(:user,
             id: i.to_s,
             username: "Student #{i}",
             trained: i % 2)

      create(:courses_user,
             id: i.to_s,
             course_id: 10001,
             user_id: i.to_s)
    end

    ratings = ['fl', 'fa', 'a', 'ga', 'b', 'c', 'start', 'stub', 'list', nil]
    (1..article_count).each do |i|
      create(:article,
             id: i,
             title: "Article #{i}",
             namespace: 0,
             wiki_id: es_wiktionary.id,
             rating: ratings[(i + 5) % 10])
    end

    # Add some revisions within the course dates
    (1..revision_count).each do |i|
      # Make half of the articles new ones.
      newness = i <= article_count ? i % 2 : 0

      create(:revision,
             id: i.to_s,
             user_id: ((i % user_count) + 1).to_s,
             article_id: ((i % article_count) + 1).to_s,
             date: '2015-03-01'.to_date,
             characters: 2,
             views: 10,
             new_article: newness)
    end

    # Add articles / revisions before the course starts and after it ends.
    create(:article,
           id: article_count + 1,
           title: 'Before',
           namespace: 0)
    create(:article,
           id: article_count + 2,
           title: 'After',
           namespace: 0)
    create(:revision,
           id: (revision_count + 1).to_s,
           user_id: 1,
           article_id: (article_count + 1).to_s,
           date: '2014-12-31'.to_date,
           characters: 9000,
           views: 9999,
           new_article: 1)
    create(:revision,
           id: (revision_count + 2).to_s,
           user_id: 1,
           article_id: (article_count + 2).to_s,
           date: '2016-01-01'.to_date,
           characters: 9000,
           views: 9999,
           new_article: 1)

    week = create(:week,
                  course_id: course.id)
    create(:block,
           kind: MILESTONE_BLOCK_KIND,
           week_id: week.id,
           content: 'blocky block')

    ArticlesCourses.update_from_course(course)
    ArticlesCourses.update_all_caches(course.articles_courses)
    CoursesUsers.update_all_caches(CoursesUsers.ready_for_update)
    Course.update_all_caches

    stub_token_request
  end

  describe 'overview' do
    it 'displays title, tab links, stats, description, school, term, dates, milestones' do
      js_visit "/courses/#{slug}"

      # Title in the header
      title_text = 'This.course'
      expect(page).to have_content title_text

      # Title in the primary overview section
      title = 'This.course'
      expect(page.find('.primary')).to have_content title

      # Description
      description = 'This is a great course'
      expect(page.find('.primary')).to have_content description

      # School
      school = 'This university'
      expect(page.find('.sidebar')).to have_content school

      # Term
      term = 'term 2015'
      expect(page.find('.sidebar')).to have_content term

      # Course dates
      startf = course_start.to_date.strftime('%Y-%m-%d')
      endf = course_end.to_date.strftime('%Y-%m-%d')
      expect(page.find('.sidebar')).to have_content startf
      expect(page.find('.sidebar')).to have_content endf

      # Links
      link = "/courses/#{slug}/home"
      expect(page.has_link?('', href: link)).to be true

      link = "/courses/#{slug}/timeline"
      expect(page.has_link?('', href: link)).to be true

      link = "/courses/#{slug}/activity"
      expect(page.has_link?('', href: link)).to be true

      link = "/courses/#{slug}/students"
      expect(page.has_link?('', href: link)).to be true

      link = "/courses/#{slug}/articles"
      expect(page.has_link?('', href: link)).to be true

      # Milestones
      within '.milestones' do
        expect(page).to have_content 'Milestones'
        expect(page).to have_content 'blocky block'
      end
    end
  end

  describe 'overview details editing' do
    it "doesn't allow null values for passcode" do
      previous_passcode = Course.last.passcode
      login_as(admin)
      sleep 5
      js_visit "/courses/#{slug}"
      within '.sidebar' do
        click_button 'Edit Details'
        find('input.passcode').set ''
        click_button 'Save'
      end
      expect(Course.last.passcode).to eq(previous_passcode)
    end

    context 'when WikiEd Feature disabled' do
      before { allow(Features).to receive(:wiki_ed?).and_return(false) }

      it 'allow edits for home_wiki' do
        login_as(admin)
        js_visit "/courses/#{slug}"
        within '.sidebar' do
          click_button 'Edit Details'
          within '.home_wiki_project' do
            find('input').set "wiktionary\n"
          end
          within '.home_wiki_language_selector' do
            find('input').set "es\n"
          end
          click_button 'Save'
        end
        sleep 2
        home_wiki_id = Course.find_by(slug: slug).home_wiki_id
        expect(home_wiki_id).to eq(es_wiktionary.id)
      end
    end
  end

  describe 'articles edited view' do
    it 'displays a list of articles, and sort articles by class' do
      js_visit "/courses/#{slug}/articles"
      # List of articles
      sleep 1
      rows = page.all('tr.article').count
      expect(rows).to eq(article_count)

      # Sorting
      # first click on the Class sorting should sort high to low
      find('th.sortable', text: 'Class').click
      first_rating = page.find(:css, 'table.articles', match: :first).first('td .rating p')
      expect(first_rating).to have_content 'FA'
      # second click should sort from low to high
      find('th.sortable', text: 'Class').click
      new_first_rating = page.find(:css, 'table.articles', match: :first).first('td .rating p')
      expect(new_first_rating).to have_content '-'
      title = page.find(:css, 'table.articles', match: :first).first('td .title')
      expect(title).to have_content 'es:wiktionary:Article'
    end

    it 'includes a list of available articles' do
      stub_info_query
      course = Course.first
      wiki = Wiki.first
      AssignmentManager.new(user_id: nil,
                            course: course,
                            wiki: wiki,
                            title: 'Education',
                            role: 0).create_assignment
      js_visit "/courses/#{slug}/articles"
      expect(page).to have_content 'Available Articles'
      assigned_articles_section = page.first(:css, '#available-articles')
      expect(assigned_articles_section).to have_content 'Education'
    end

    it 'does not show an "Add an available article" button for students' do
      js_visit "/courses/#{slug}/articles"
      expect(page).not_to have_content 'Available Articles'
      expect(page).not_to have_content 'Add available articles'
    end

    it 'shows an "Add an available article" button for instructors/admins' do
      login_as(admin)
      js_visit "/courses/#{slug}/articles"
      expect(page).to have_content 'Available Articles'
      assigned_articles_section = page.find(:css, '#available-articles', match: :first)
      expect(assigned_articles_section).to have_content 'Add available articles'
    end

    it 'allow instructor to add an available article' do
      stub_info_query
      login_as(admin)
      stub_oauth_edit
      js_visit "/courses/#{slug}/articles"
      expect(page).to have_content 'Available Articles'
      click_button 'Add available articles'
      page.find(:css, '#available-articles .pop.open', match: :first).first('textarea')
          .set('Education')
      click_button 'Add articles'
      sleep 1
      assigned_articles_table = page.find(:css, '#available-articles table.articles', match: :first)
      expect(assigned_articles_table).to have_content 'Education'
    end

    it 'allows instructor to remove an available article' do
      stub_info_query
      stub_raw_action
      Assignment.destroy_all
      login_as(admin)
      stub_oauth_edit
      course = Course.first
      wiki = Wiki.first
      AssignmentManager.new(user_id: nil,
                            course: course,
                            wiki: wiki,
                            title: 'Education',
                            role: 0).create_assignment
      js_visit "/courses/#{slug}/articles"
      assigned_articles_section = page.find(:css, '#available-articles', match: :first)
      expect(assigned_articles_section).to have_content 'Education'
      expect(Assignment.count).to eq(1)
      expect(assigned_articles_section).to have_content 'Remove'
      accept_alert do
        click_button 'Remove'
      end
      expect(assigned_articles_section).not_to have_content 'Education'
    end

    it 'allows student to select an available article' do
      VCR.use_cassette 'assigned_articles_item' do
        stub_info_query
        user = create(:user, id: user_count + 100)
        course = Course.first
        create(:courses_user, course_id: course.id, user_id: user.id,
                              role: CoursesUsers::Roles::STUDENT_ROLE)
        wiki = Wiki.first
        AssignmentManager.new(user_id: nil,
                              course: course,
                              wiki: wiki,
                              title: 'Education',
                              role: 0).create_assignment

        login_as(user, scope: :user)
        js_visit "/courses/#{slug}/articles"
        expect(page).to have_content 'Available Articles'
        assigned_articles_section = page.find(:css, '#available-articles', match: :first)
        expect(assigned_articles_section).to have_content 'Education'
        expect(Assignment.count).to eq(1)
        expect(assigned_articles_section).to have_content 'Select'
        click_button 'Select'
        sleep 1
        expect(Assignment.first.user_id).to eq(user.id)
        expect(Assignment.first.role).to eq(0)
      end
    end
  end

  describe 'students view' do
    before do
      Revision.last.update_attributes(date: 2.days.ago, user_id: User.first.id)
      CoursesUsers.last.update_attributes(
        course_id: Course.find_by(slug: slug).id,
        user_id: User.first.id
      )
      CoursesUsers.update_all_caches CoursesUsers.all
    end

    it 'shows a number of most recent revisions for a student' do
      js_visit "/courses/#{slug}/students"
      sleep 1
      expect(page).to have_content(User.last.username)
      student_row = 'table.users tbody tr.students:first-child'
      within(student_row) do
        expect(page).to have_content User.first.username
        within 'td:nth-of-type(4)' do
          expect(page.text).to eq('1')
        end
      end
    end
  end

  describe 'uploads view' do
    it 'displays a list of uploads' do
      # First, visit it no uploads
      visit "/courses/#{slug}/uploads"
      expect(page).to have_content I18n.t('courses_generic.uploads_none')
      create(:commons_upload,
             user_id: 1,
             file_name: 'File:Example.jpg',
             uploaded_at: '2015-06-01',
             thumburl: 'https://upload.wikimedia.org/wikipedia/commons/c/c3/Real_Grottolella.png')
      visit "/courses/#{slug}/uploads"
      expect(page).to have_selector('div.upload')
      expect(page).not_to have_content I18n.t('courses_generic.uploads_none')
    end
  end

  describe 'activity view' do
    it 'displays a list of edits' do
      js_visit "/courses/#{slug}/activity"
      expect(page).to have_content 'Article 1'
    end
  end

  describe '/manual_update' do
    it 'updates the course cache' do
      user = create(:user, id: user_count + 100)
      course = Course.find(10001)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: 0)
      login_as(user, scope: :user)
      stub_oauth_edit

      expect(CourseRevisionUpdater).to receive(:import_new_revisions)
      expect_any_instance_of(CourseUploadImporter).to receive(:run)
      visit "/courses/#{slug}/manual_update"
      js_visit "/courses/#{slug}"
      updated_user_count = user_count + 1
      expect(page).to have_content "#{updated_user_count}\nStudent Editors"
    end
  end

  describe 'timeline' do
    it 'does not show authenticated links to a logged out user' do
      js_visit "/courses/#{Course.last.slug}/timeline"

      within '.timeline__week-nav' do
        expect(page).not_to have_content 'Edit Course Dates'
        expect(page).not_to have_content 'Add Week'
      end
    end
  end
end
