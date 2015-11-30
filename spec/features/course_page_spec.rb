require 'rails_helper'

MILESTONE_BLOCK_KIND = 2

# Wait one second after loading a path
# Allows React to properly load the page
# Remove this after implementing server-side rendering
def js_visit(path)
  visit path
  sleep 1
end

user_count = 10
article_count = 19
revision_count = 214
# Dots in course titles will cause errors if routes.rb is misconfigured.
slug = 'This_university.foo/This.course_(term_2015)'
course_start = '2015-01-01'
course_end = '2015-12-31'

describe 'the course page', type: :feature do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.driver.browser.manage.window.resize_to(1920, 1080)

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
                    listed: 1,
                    description: 'This is a great course')
    cohort = create(:cohort)
    course.cohorts << cohort

    (1..user_count).each do |i|
      create(:user,
             id: i.to_s,
             wiki_id: "Student #{i}",
             trained: i % 2)
      create(:courses_user,
             id: i.to_s,
             course_id: 10001,
             user_id: i.to_s)
    end

    ratings = ['fl', 'fa', 'a', 'ga', 'b', 'c', 'start', 'stub', 'list', nil]
    (1..article_count).each do |i|
      create(:article,
             id: i.to_s,
             title: "Article #{i}",
             namespace: 0,
             language: 'es',
             rating: ratings[(i + 5) % 10])
    end

    # Add some revisions within the course dates
    (1..revision_count).each do |i|
      # Make half of the articles new ones.
      newness = (i <= article_count) ? i % 2 : 0

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
           id: (article_count + 1).to_s,
           title: 'Before',
           namespace: 0)
    create(:article,
           id: (article_count + 2).to_s,
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

    ArticlesCourses.update_from_revisions
    ArticlesCourses.update_all_caches
    CoursesUsers.update_all_caches
    Course.update_all_caches
  end

  before :each do
    js_visit "/courses/#{slug}"
    sleep 1 # Try to avoid issue where this test fails with 0 rows found.
  end

  describe 'header', js: true do
    it 'should display the course title' do
      title_text = 'This.course'
      expect(page.find('.title')).to have_content title_text
    end

    it 'should display course-wide statistics' do
      new_articles = (article_count / 2.to_f).ceil.to_s
      expect(page.find('#articles-created')).to have_content new_articles
      expect(page.find('#total-edits')).to have_content revision_count
      expect(page.find('#articles-edited')).to have_content article_count
      expect(page.find('#student-editors')).to have_content user_count
      find('#student-editors').click
      expect(page.find('#trained-count')).to have_content user_count / 2
      characters = revision_count * 2
      expect(page.find('#characters-added')).to have_content characters
      expect(page.find('#view-count')).to have_content article_count * 10
    end
  end

  describe 'overview', js: true do
    it 'should display title' do
      title = 'This.course'
      expect(page.find('.primary')).to have_content title
    end

    it 'should display description' do
      description = 'This is a great course'
      expect(page.find('.primary')).to have_content description
    end

    it 'should display school' do
      school = 'This university'
      expect(page.find('.sidebar')).to have_content school
    end

    it 'should display term' do
      term = 'term 2015'
      expect(page.find('.sidebar')).to have_content term
    end

    it 'should show the course dates' do
      startf = course_start.to_date.strftime('%Y-%m-%d')
      endf = course_end.to_date.strftime('%Y-%m-%d')
      expect(page.find('.sidebar')).to have_content startf
      expect(page.find('.sidebar')).to have_content endf
    end
  end

  describe 'navigation bar', js: true do
    it 'should link to overview' do
      link = "/courses/#{slug}/overview"
      expect(page.has_link?('', href: link)).to be true
    end

    it 'should link to timeline' do
      link = "/courses/#{slug}/timeline"
      expect(page.has_link?('', href: link)).to be true
    end

    it 'should link to activity' do
      link = "/courses/#{slug}/activity"
      expect(page.has_link?('', href: link)).to be true
    end

    it 'should link to students' do
      link = "/courses/#{slug}/students"
      expect(page.has_link?('', href: link)).to be true
    end

    it 'should link to articles' do
      link = "/courses/#{slug}/articles"
      expect(page.has_link?('', href: link)).to be true
    end
  end

  # Something is broken here. Need to fully investigate testing React-driven UI
  # describe 'control bar' do
  # describe 'control bar' do
  #   it 'should allow sorting via dropdown', js: true do
  #     visit "/courses/#{slug}/students"
  #     selector = 'table.students > thead > tr > th'
  #     select 'Name', from: 'sorts'
  #     expect(page.all(selector)[0][:class]).to have_content 'asc'
  #     select 'Assigned Article', from: 'sorts'
  #     expect(page.all(selector)[1][:class]).to have_content 'asc'
  #     select 'Reviewer', from: 'sorts'
  #     expect(page.all(selector)[2][:class]).to have_content 'asc'
  #     select 'MS Chars Added', from: 'sorts'
  #     expect(page.all(selector)[3][:class]).to have_content 'desc'
  #     select 'US Chars Added', from: 'sorts'
  #     expect(page.all(selector)[4][:class]).to expect 'desc'
  #   end
  # end

  describe 'overview view', js: true do
    it 'should be the same as the root view' do
      root_content = page
      js_visit "/courses/#{slug}"
      expect(root_content).to eq(page)
    end

    it 'displays a list of milestone blocks' do
      within '.milestones' do
        expect(page).to have_content 'Milestones'
        expect(page).to have_content 'blocky block'
      end
    end

    it "doesn't allow null values for course start/end" do
      admin = create(:admin, id: User.last.id + 1)
      login_as(admin)
      js_visit "/courses/#{slug}"
      within '.sidebar' do
        click_button 'Edit Details'
      end
      fill_in 'Start:', with: ''
      within 'input.start' do
        # TODO: Capybara seems to be able to clear this field.
        # expect(page).to have_text Course.first.start.strftime("%Y-%m-%d")
      end
      # expect(page).to have_css('button.dark[disabled="disabled"]')
    end

    it "doesn't allow null values for passcode" do
      admin = create(:admin, id: User.last.id + 1)
      previous_passcode = Course.last.passcode
      login_as(admin)
      js_visit "/courses/#{slug}"
      within '.sidebar' do
        click_button 'Edit Details'
        find('input.passcode').set ''
        click_button 'Save'
      end
      expect(Course.last.passcode).to eq(previous_passcode)
    end
  end

  describe 'articles edited view', js: true do
    it 'should display a list of articles' do
      js_visit "/courses/#{slug}/articles"
      rows = page.all('tr.article').count
      expect(rows).to eq(article_count)
    end

    it 'should sort article by class' do
      js_visit "/courses/#{slug}/articles"
      sleep 1 # Try to avoid intermittent test failures
      # first click on the Class sorting should sort high to low
      find('th.sortable', text: 'Class').click
      first_rating = page.find(:css, 'table.articles').first('td .rating p')
      expect(first_rating).to have_content 'FA'
      # second click should sort from low to high
      find('th.sortable', text: 'Class').click
      new_first_rating = page.find(:css, 'table.articles').first('td .rating p')
      expect(new_first_rating).to have_content '-'
      title = page.find(:css, 'table.articles').first('td p.title')
      expect(title).to have_content 'es:Article'
    end
  end

  describe 'students view', js: true do
    before do
      Revision.last.update_attributes(date: 2.days.ago, user_id: User.first.id)
      CoursesUsers.last.update_attributes(
        course_id: Course.find_by(slug: slug).id,
        user_id: User.first.id
      )
    end
    it 'shows a number of most recent revisions for a student' do
      js_visit "/courses/#{slug}/students"
      sleep 1
      expect(page).to have_content(User.last.wiki_id)
      student_row = 'table.users tbody tr.students:first-child'
      within(student_row) do
        expect(page).to have_content User.first.wiki_id
        within 'td:nth-of-type(4)' do
          expect(page.text).to eq('1')
        end
      end
    end
  end

  describe 'uploads view', js: true do
    it 'should display a list of uploads' do
      # First, visit it no uploads
      visit "/courses/#{slug}/uploads"
      expect(page).to have_content "#{I18n.t('uploads.none')}"
      create(:commons_upload,
             user_id: 1,
             file_name: 'File:Example.jpg',
             uploaded_at: '2015-06-01')
      js_visit "/courses/#{slug}/uploads"
      expect(page).to have_content 'Example.jpg'
    end
  end

  describe 'activity view', js: true do
    it 'should display a list of edits' do
      js_visit "/courses/#{slug}/activity"
      expect(page).to have_content 'Article 1'
    end
  end

  describe '/manual_update', js: true do
    it 'should update the course cache' do
      user = create(:user, id: user_count + 100)
      course = Course.find(10001)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: 0)
      login_as(user, scope: :user)
      stub_oauth_edit

      Dir["#{Rails.root}/lib/importers/*.rb"].each { |file| require file }
      allow(UserImporter).to receive(:update_users)
      allow(RevisionImporter).to receive(:update_all_revisions)
      allow(ViewImporter).to receive(:update_views)
      allow(RatingImporter).to receive(:update_ratings)

      js_visit "/courses/#{slug}/manual_update"
      js_visit "/courses/#{slug}"
      updated_user_count = user_count + 1
      expect(page.find('#student-editors')).to have_content updated_user_count
    end
  end

  after do
    Capybara.use_default_driver
  end
end
