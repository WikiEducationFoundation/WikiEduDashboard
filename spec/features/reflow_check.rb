# frozen_string_literal: true

# Manual-only: renders a sample of representative pages at a 320 CSS
# pixel viewport width and pauses so a human can visually verify WCAG
# 2.1 1.4.10 Reflow conformance.
#
# WCAG 1.4.10: content can be presented "without loss of information or
# functionality, and without requiring scrolling in two dimensions for
# vertical scrolling content at a width equivalent to 320 CSS pixels".
#
# What to look for at 320 CSS px on each page:
#   - Horizontal scrolling at the page level (a 1.4.10 failure).
#   - Any text clipped or hidden behind another element.
#   - Buttons or controls that become unclickable (off-screen, overlapped).
#   - Modal close buttons or form actions unreachable due to viewport size.
#   - Tables that don't reflow and cause horizontal overflow.
#   - Fixed-width charts or diagrams that don't fit.
#
# Run with:
#   HEADED=1 SLOW=1 OBSERVE=5 bundle exec rspec spec/features/reflow_check.rb
#
# HEADED=1 is required so a browser opens. SLOW adds the existing per-action
# slow-mode pause. OBSERVE is the per-page observation pause in seconds
# (defaults to 5). Screenshots of each narrow-viewport page are saved to
# tmp/reflow_check_screenshots/ for later review.

require 'rails_helper'
require "#{Rails.root}/lib/assignment_manager"

describe 'reflow at 320 CSS px check', type: :feature, js: true, reflow: true do
  let(:screenshot_dir) { Rails.root.join('tmp', 'reflow_check_screenshots') }
  let(:observe_seconds) { (ENV['OBSERVE'] || '5').to_f }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    # Force the layout viewport to exactly 320 CSS px wide via Chrome
    # DevTools Protocol. `page.current_window.resize_to(360, 900)`
    # would be silently clamped by Chrome's headed-mode minimum
    # window width (~500 CSS px on most platforms), so the page
    # wouldn't actually render at the 1.4.10 target width.
    # `Emulation.setDeviceMetricsOverride` overrides the layout
    # viewport regardless of physical window size.
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',
                                    width: 320, height: 900,
                                    deviceScaleFactor: 1,
                                    mobile: false)
  end

  after do
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end

  # Visit a page, wait for it to settle, then sleep so the user can inspect
  # the narrow-viewport rendering. Save a screenshot for later review.
  def observe_at_320(snapshot_name)
    sleep observe_seconds
    page.save_screenshot(screenshot_dir.join("#{snapshot_name}.png"))
  end

  describe 'logged-out home' do
    it 'snapshot' do
      visit root_path
      expect(page).to have_content I18n.t('application.log_in')
      observe_at_320('01_logged_out_home')
    end
  end

  describe 'explore page' do
    before do
      create(:campaign, title: 'Sample Campaign A',
                        start: Date.civil(2016, 1, 10),
                        end: Date.civil(2050, 2, 10))
      create(:course, title: 'A sample course',
                      slug: 'foo/sample_course',
                      start: Date.civil(2016, 1, 10),
                      end: Date.civil(2050, 1, 10))
    end

    it 'snapshot' do
      visit '/explore'
      expect(page).to have_content 'Sample Campaign A'
      observe_at_320('02_explore')
    end
  end

  # Every tab of the course page, against a single populated course
  # (students, articles, revisions, assignments, uploads, and a
  # multi-week timeline). Adapted from spec/features/course_page_spec.rb's
  # `before` block, scaled down somewhat to keep this spec fast.
  describe 'populated course page tabs' do
    course_slug = 'Sample_University/Resize_test_course_(Spring_2025)'
    course_start_date = '2025-02-10'.to_date
    student_count = 8
    article_count = 10
    revision_count = 40

    let(:course) { Course.find_by(slug: course_slug) }

    before do
      ActionController::Base.allow_forgery_protection = true
      stub_wiki_validation
      stub_token_request
      TrainingModule.load_all

      home_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
      course = create(:course,
                      title: 'Resize-text test course',
                      slug: course_slug,
                      school: 'Sample University',
                      term: 'Spring 2025',
                      start: course_start_date,
                      end: course_start_date + 4.months,
                      timeline_start: course_start_date,
                      timeline_end: course_start_date + 4.months,
                      weekdays: '0101010',
                      home_wiki_id: home_wiki.id,
                      description: 'A realistic sample course for visual layout checks.')
      campaign = create(:campaign, title: 'Sample campaign')
      course.campaigns << campaign

      # Instructor + students
      instructor = create(:user, username: 'Professor Resize', real_name: 'Pat Example')
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      students = []
      (1..student_count).each do |i|
        student = create(:user, username: "Student#{i}",
                                real_name: "Student #{i} Surname",
                                trained: i.odd?)
        create(:courses_user, course:, user: student,
                              role: CoursesUsers::Roles::STUDENT_ROLE)
        students << student
      end

      # Articles + revisions
      ratings = ['fa', 'ga', 'b', 'c', 'start', 'stub', nil]
      articles = (1..article_count).map do |i|
        create(:article, title: "Wikipedia_article_#{i}",
                         namespace: 0, wiki_id: home_wiki.id,
                         rating: ratings[(i - 1) % ratings.length])
      end

      revisions = []
      (1..revision_count).each do |i|
        revisions << build(:revision_on_memory,
                           user_id: students[(i - 1) % student_count].id.to_s,
                           article_id: articles[(i - 1) % article_count].id.to_s,
                           date: course_start_date + 5.days,
                           characters: 50 + (i * 5),
                           new_article: (i.odd? && i <= article_count) ? 1 : 0,
                           scoped: true)
      end

      # Assignments (first 4 students get an article each)
      articles.first(4).each_with_index do |article, i|
        create(:assignment,
               course:, user: students[i], article:,
               role: Assignment::Roles::ASSIGNED_ROLE,
               article_title: article.title,
               wiki_id: home_wiki.id)
      end

      # Uploads. Use inline SVG data URLs so the thumbnails render
      # realistically regardless of network state; otherwise broken-
      # image placeholders would obscure the layout under inspection.
      upload_thumbs = %w[%23488 %23A45 %2349A %2398C %23C57 %234C9]
      3.times do |i|
        color = upload_thumbs[i % upload_thumbs.length]
        svg = "<svg xmlns='http://www.w3.org/2000/svg' width='400' " \
              "height='300'><rect width='100%25' height='100%25' " \
              "fill='#{color}'/><text x='50%25' y='50%25' " \
              "text-anchor='middle' dominant-baseline='central' " \
              "fill='white' font-family='sans-serif' " \
              "font-size='60'>Sample #{i + 1}</text></svg>"
        create(:commons_upload,
               user_id: students[i].id,
               file_name: "File:Sample_upload_#{i + 1}.jpg",
               uploaded_at: course_start_date + 10.days,
               usage_count: i,
               thumburl: "data:image/svg+xml;utf8,#{svg}",
               thumbwidth: '400', thumbheight: '300')
      end

      # Timeline weeks + blocks. The first assignment block references
      # a couple of training modules so the rendered timeline includes
      # a Continue / Start link with the standard training-module
      # icon (one of the layout pain points at 200% browser zoom).
      week1 = create(:week, course:, order: 1)
      create(:block, week: week1, kind: Block::KINDS['assignment'],
                     title: 'Choose your article', order: 0,
                     training_module_ids: [1, 2])
      create(:block, week: week1, kind: Block::KINDS['in_class'],
                     title: 'In-class discussion of source evaluation', order: 1)
      week2 = create(:week, course:, order: 2)
      create(:block, week: week2, kind: Block::KINDS['milestone'],
                     title: 'First draft due', order: 0, points: 25)
      create(:block, week: week2, kind: Block::KINDS['assignment'],
                     title: 'Peer review your classmates', order: 1,
                     training_module_ids: [3])

      ArticlesCourses.update_from_course_revisions(course, revisions)
      ArticlesCourses.update_all_caches_from_timeslices(course.articles_courses)
      CoursesUsers.update_all_caches_from_timeslices(course.courses_users)
      course.update_cache_from_timeslices

      login_as instructor
    end

    after { ActionController::Base.allow_forgery_protection = false }

    it 'home tab' do
      visit "/courses/#{course.slug}/home"
      expect(page).to have_content course.title
      observe_at_320('03a_course_home')
    end

    it 'timeline tab' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Choose your article'
      observe_at_320('03b_course_timeline')
    end

    it 'students tab' do
      visit "/courses/#{course.slug}/students"
      expect(page).to have_content 'Student1'
      observe_at_320('03c_course_students')
    end

    it 'articles tab' do
      visit "/courses/#{course.slug}/articles"
      expect(page).to have_content 'Wikipedia article 1'
      observe_at_320('03d_course_articles')
    end

    it 'uploads tab' do
      visit "/courses/#{course.slug}/uploads"
      expect(page).to have_selector('div.upload', minimum: 1)
      observe_at_320('03e_course_uploads')
    end

    it 'activity tab' do
      Capybara.using_wait_time 10 do
        visit "/courses/#{course.slug}/activity"
        expect(page).to have_css('.revision', minimum: 1)
        observe_at_320('03f_course_activity')
      end
    end

    it 'resources tab' do
      visit "/courses/#{course.slug}/resources"
      expect(page).to have_content course.title
      observe_at_320('03g_course_resources')
    end
  end

  describe 'course creation modal' do
    let(:instructor) do
      create(:user, id: 1, permissions: User::Permissions::INSTRUCTOR)
    end

    before do
      TrainingModule.load_all
      stub_oauth_edit
      create(:training_modules_users, user_id: instructor.id,
                                      training_module_id: 3,
                                      completed_at: Time.zone.now)
      login_as instructor, scope: :user
    end

    it 'snapshot' do
      visit root_path
      click_link 'Create Course'
      expect(page).to have_content 'Create a New Course'
      observe_at_320('04_course_creator_modal')
    end
  end

  describe 'survey admin' do
    let(:admin) { create(:admin) }

    before do
      create(:survey, name: 'Sample Survey')
      login_as admin
    end

    it 'snapshot' do
      visit '/surveys'
      expect(page).to have_content 'Sample Survey'
      observe_at_320('05_survey_admin')
    end
  end

  describe 'admin dashboard' do
    let(:admin) { create(:admin) }
    let(:instructor) { create(:user, username: 'Professor Sample') }
    let!(:submitted_course) do
      create(:course, title: 'A submitted course', school: 'Sample U',
                      term: 'Spring 2025',
                      slug: 'Sample_U/A_submitted_course_(Spring_2025)',
                      submitted: true,
                      start: '2025-01-01'.to_date, end: '2025-06-01'.to_date)
    end
    let!(:courses_user) do
      create(:courses_user, user: instructor, course: submitted_course,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    before { login_as admin }

    it 'snapshot' do
      visit root_path
      expect(page).to have_content 'Submitted & Pending Approval'
      observe_at_320('06_admin_dashboard')
    end
  end

  describe 'onboarding' do
    let(:user) { create(:user, onboarded: false, real_name: 'Sample', email: 'sample@example.com') }

    before do
      stub_list_users_query
      login_as user, scope: :user
    end

    it 'snapshot' do
      visit onboarding_path
      expect(page).to have_content 'excited'
      observe_at_320('07_onboarding')
    end
  end
end
