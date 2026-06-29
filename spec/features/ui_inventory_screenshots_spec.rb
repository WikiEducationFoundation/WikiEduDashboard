# frozen_string_literal: true

# Visits every user-facing page and saves a PNG screenshot to docs/screenshots/.
#
# Opt-in: set SCREENSHOTS=1 to run. Intentionally excluded from the default
# test suite. Purpose is to (re)generate the illustrated UI inventory at
# docs/ui_inventory.md.
#
# Usage:
#   SCREENSHOTS=1 bundle exec rspec spec/features/ui_inventory_screenshots_spec.rb
#
# The spec is grouped by auth context. Each `it` block recreates its own data
# in a fresh DB transaction and re-logs-in. Failures on any single page log a
# warning but don't abort the run, so we get partial output even when some
# pages 500 or hang.

require 'rails_helper'

if ENV['SCREENSHOTS']
  describe 'UI inventory screenshots',
           type: :feature, js: true, js_error_expected: true do
    SCREENSHOT_DIR = Rails.root.join('docs/screenshots')

    # Pinned date that all `*.days.ago` / `*.days.from_now` and ActiveRecord
    # timestamps resolve against. Bump this only when you intend the baseline
    # to move.
    FROZEN_DATE = Date.new(2025, 5, 14)

    before(:all) do
      FileUtils.mkdir_p(SCREENSHOT_DIR)
      # A real API call returning mwoauth-invalid-authorization will mark the
      # logged-in test user's wiki_token as 'invalid', which then redirects every
      # subsequent request to root with a flash. Skip that for the run.
      ApplicationController.skip_before_action :check_for_expired_oauth_credentials, raise: false
    end

    after(:all) do
      ApplicationController.before_action :check_for_expired_oauth_credentials
    end

    # Pin time and use a per-example VCR cassette so every Wikimedia / LiftWing
    # / etc. response is replayed from a committed file. First-run records
    # against the live APIs; subsequent runs are network-free and reproducible.
    around do |example|
      cassette = "cached/ui_inventory_screenshots/" \
                 "#{example.description.parameterize}"
      travel_to FROZEN_DATE do
        VCR.use_cassette(cassette, record: :new_episodes) do
          example.run
        end
      end
    end

    before do
      # CoursesController#show calls verify_edit_credentials which makes a real
      # Wikipedia OAuth check and redirects on failure. Treat the dashboard as
      # if wiki output is disabled so the check is short-circuited.
      allow(Features).to receive(:disable_wiki_output?).and_return(true)
    end

    def shoot(name, wait: 1.0, wait_for: nil)
      expect(page).to have_css(wait_for, wait: 15) if wait_for
      sleep(wait) if wait.positive?
      page.save_screenshot(SCREENSHOT_DIR.join("#{name}.png").to_s)
      puts "  ✓ #{name}.png"
    rescue StandardError => e
      warn "  ✗ #{name}: #{e.class}: #{e.message.to_s[0..200]}"
    end

    it 'anonymous pages' do
      faq = create(:faq, title: 'How do I add a citation to a Wikipedia article?',
                         content: "Citations use `<ref>` tags around the source. " \
                                  'See the [training](/training) module for examples.')

      visit '/'
      shoot('home_marketing', wait: 2.0)

      visit '/explore'
      shoot('explore', wait: 1.5)

      visit '/faq'
      shoot('faq_index')

      visit "/faq/#{faq.id}"
      shoot('faq_show')

      visit '/private_information'
      shoot('private_information')

      visit '/sign_in'
      shoot('sign_in')

      visit '/404'
      shoot('error_404')

      visit '/errors/internal_server_error'
      shoot('error_500')

      visit '/errors/login_error'
      shoot('error_login')
    end

    context 'un-onboarded user' do
      let(:newcomer) { create(:user, username: 'NewLearner', onboarded: false) }

      it 'onboarding flow' do
        login_as(newcomer, scope: :user)

        visit '/onboarding'
        shoot('onboarding_intro', wait: 2.0)

        visit '/onboarding/form'
        shoot('onboarding_form', wait: 2.0)

        visit '/onboarding/supplementary'
        shoot('onboarding_supplementary', wait: 2.0)

        visit '/onboarding/permissions'
        shoot('onboarding_permissions', wait: 2.0)

        visit '/onboarding/finish'
        shoot('onboarding_finish', wait: 2.0)
      end
    end

    context 'authenticated as a regular user' do
      let(:user) { create(:user) }

      it 'dashboard, course_creator, feedback' do
        login_as(user, scope: :user)

        visit '/'
        shoot('dashboard_my_courses', wait: 2.0)

        visit '/my_account'
        shoot('my_account')

        visit '/feedback'
        shoot('feedback_form')

        visit '/feedback/confirmation'
        shoot('feedback_confirmation')

        visit '/article_finder'
        shoot('article_finder', wait: 2.0)
        # Drive a real keyword search to capture the results state.
        find('#article-searchbar').set('Common loon')
        find('#article-searchbar').send_keys(:return)
        shoot('article_finder_results', wait: 5.0)
      end

      it 'course listings' do
        # /active_courses' JSON endpoint scopes to courses whose start <= now <=
        # end AND end < 3.days.from_now, so seed one "wrapping up" course.
        active = create(:course,
                        title: 'Astronomy Wrapping Up',
                        school: 'Demo University',
                        term: 'Spring 2025',
                        slug: 'Demo_University/Astronomy_Wrapping_Up_(Spring_2025)',
                        start: 60.days.ago,
                        end: 2.days.from_now,
                        user_count: 24, character_sum: 56_000,
                        recent_revision_count: 73, view_sum: 2400)
        create(:campaigns_course, campaign: Campaign.first || create(:campaign),
                                  course: active)

        # /unsubmitted_courses scopes to courses with NO campaign association
        # and submitted=false. Seed a couple.
        create(:course,
               title: 'Marine Biology Draft',
               school: 'Coastal College', term: 'Fall 2025',
               slug: 'Coastal_College/Marine_Biology_Draft_(Fall_2025)',
               start: 30.days.from_now, end: 180.days.from_now,
               submitted: false)
        create(:course,
               title: 'World History Draft',
               school: 'Demo University', term: 'Fall 2025',
               slug: 'Demo_University/World_History_Draft_(Fall_2025)',
               start: 60.days.from_now, end: 200.days.from_now,
               submitted: false)

        login_as(user, scope: :user)

        visit '/active_courses'
        shoot('active_courses', wait: 2.0)

        visit '/unsubmitted_courses'
        shoot('unsubmitted_courses')

        visit '/courses_by_wiki/en.wikipedia.org'
        shoot('courses_by_wiki', wait: 2.0)
      end
    end

    context 'course creation walkthrough' do
      # Drives the course creator → "Research and write" timeline wizard end
      # to end, capturing each stage. Then seeds a few students/articles on the
      # resulting course and screenshots every course tab.
      #
      # The interaction sequence (selectors, click targets, sleep waits)
      # mirrors `go_through_researchwrite_wizard` in
      # spec/features/course_creation_spec.rb — see there if anything stops
      # matching after a wizard config change.

      let(:instructor) do
        create(:user, permissions: User::Permissions::INSTRUCTOR,
                      onboarded: true, real_name: 'Prof. Demo')
      end

      def wizard_next
        click_button 'Next'
        sleep 1
      end

      def pick_first_wizard_option
        find('.wizard__option', match: :first).find('button', match: :first).click
      end

      it 'creator + research-and-write wizard + tabs' do
        TrainingModule.load_all
        stub_oauth_edit
        create(:training_modules_users, user_id: instructor.id,
                                        training_module_id: 3,
                                        completed_at: Time.zone.now)
        allow_any_instance_of(User).to receive(:returning_instructor?)
          .and_return(true)
        login_as(instructor, scope: :user)

        # ---------- Course Creator ----------
        visit '/course_creator'
        sleep 2
        shoot('course_creator_form', wait: 0)

        find('#course_title').set('Intro to Wikipedia Editing')
        find('#course_school').set('Demo University')
        find('#course_term').set('Spring 2025')
        find('#course_subject').click
        within('#course_subject') { all('div', text: 'Chemistry')[2].click }
        find('#course_expected_students').set('25')
        find('#course_level').click
        within('#course_level') { all('div', text: 'Introductory')[2].click }
        find('#course_format').click
        within('#course_format') { all('div', text: 'In-person')[2].click }
        find('#course_description').set('A sample course used for the ' \
                                        'illustrated UI inventory walkthrough.')
        shoot('course_creator_form_filled', wait: 0)
        click_button 'Next'
        sleep 1

        # Dates stage of the creator.
        find('.course_start-datetime-control input').set('2025-04-01')
        find('div.DayPicker-Day--selected', text: '1').click
        find('.course_end-datetime-control input').set('2025-12-01')
        find('div.DayPicker-Day', text: '15').click
        sleep 1
        shoot('course_creator_dates', wait: 0)
        click_button 'Create my Course!'

        # ---------- Timeline Wizard (Research and write) ----------
        sleep 3
        shoot('course_wizard_dates', wait: 0)
        # Pick a weekday, then "no blackout dates" so we can advance.
        find('span[title="Wednesday"]', match: :first).click
        find('.wizard__form.course-dates input[type=checkbox]', match: :first)
          .set(true)
        wizard_next

        shoot('course_wizard_path', wait: 0)
        pick_first_wizard_option # Research and write
        wizard_next

        shoot('course_wizard_training', wait: 0)
        pick_first_wizard_option # Training graded
        wizard_next

        shoot('course_wizard_ai', wait: 0)
        pick_first_wizard_option # AI training
        wizard_next

        shoot('course_wizard_getting_started', wait: 0)
        wizard_next # accept defaults

        shoot('course_wizard_representation', wait: 0)
        wizard_next # accept defaults

        shoot('course_wizard_sandboxes', wait: 0)
        pick_first_wizard_option # Draft in sandboxes
        wizard_next

        shoot('course_wizard_groups', wait: 0)
        pick_first_wizard_option # Individually
        wizard_next

        shoot('course_wizard_articles_source', wait: 0)
        pick_first_wizard_option # Instructor prepares list
        wizard_next

        shoot('course_wizard_medical', wait: 0)
        pick_first_wizard_option # Yes/medical
        wizard_next

        shoot('course_wizard_handouts', wait: 0)
        omniclick find('.wizard__option', match: :first).find('button', match: :first)
        wizard_next

        shoot('course_wizard_peer_review', wait: 0)
        wizard_next # default 2 reviews

        shoot('course_wizard_discussions', wait: 0)
        wizard_next # default discussions

        shoot('course_wizard_supplementary', wait: 0)
        find('h3', text: 'Extra credit assignment').click
        wizard_next

        shoot('course_wizard_expectations', wait: 0)
        omniclick find('.wizard__option', match: :first).find('button', match: :first)
        wizard_next

        shoot('course_wizard_weight', wait: 0)
        omniclick find('.wizard__option', match: :first).find('button', match: :first)
        wizard_next

        shoot('course_wizard_summary', wait: 0)
        click_button 'Generate Timeline'
        sleep 3

        # ---------- Course tabs on the wizard-generated course ----------
        course = Course.last
        # The creator generates a random passcode; pin it so the overview
        # screenshot is byte-stable across runs.
        course.update!(passcode: 'demopass')
        slug = course.slug
        article = create(:article, title: 'Common_loon')
        create(:articles_course, course:, article:,
                                 character_sum: 2_400, references_count: 7,
                                 view_count: 480)
        ['StudentA', 'StudentB', 'StudentC'].each do |username|
          student = create(:user, username:)
          CoursesUsers.create!(user: student, course:,
                               role: CoursesUsers::Roles::STUDENT_ROLE,
                               revision_count: 4 + rand(8))
        end
        create(:assignment, course:, user_id: course.students.first&.id,
                            article:, article_title: article.title)

        visit "/courses/#{slug}/home"
        shoot('course_overview', wait: 2.5)

        visit "/courses/#{slug}/timeline"
        shoot('course_timeline', wait: 2.0)

        visit "/courses/#{slug}/activity"
        shoot('course_activity', wait: 2.0)

        visit "/courses/#{slug}/students"
        shoot('course_students', wait: 2.0)

        visit "/courses/#{slug}/articles"
        shoot('course_articles', wait: 2.0)

        visit "/courses/#{slug}/uploads"
        shoot('course_uploads', wait: 2.0)

        visit "/courses/#{slug}/resources"
        shoot('course_resources', wait: 1.5)

        visit "/courses/#{slug}/article_finder"
        shoot('course_article_finder', wait: 2.0)

        visit "/courses/#{slug}/timeline/wizard"
        shoot('course_timeline_wizard', wait: 2.5)
      end
    end

    context 'admin pages' do
      # super_admin so that super-admin-only tools (e.g. /timeslice_duration)
      # render their actual UI instead of the access-denied login card.
      let(:admin) { create(:super_admin) }
      let(:campaign) do
        existing = Campaign.find_by(slug: 'spring_2015')
        if existing
          existing.update!(description: 'A demo campaign showcasing the Spring ' \
                                       '2025 cohort of classroom programs.')
          existing
        else
          create(:campaign, title: 'Demo Campaign', slug: 'demo_campaign',
                            description: 'A demo campaign.')
        end
      end
      let(:course) do
        create(:course,
               title: 'Intro to Wikipedia Editing',
               school: 'Demo University',
               term: 'Spring 2025',
               slug: 'Demo_University/Intro_to_Wikipedia_Editing_(Spring_2025)',
               user_count: 12, character_sum: 24_500)
      end
      let(:tag) { create(:tag, course:, tag: 'demo-tag') }

      before do
        create(:campaigns_course, campaign:, course:)
        tag # touch to create

        # Students in the course → /campaigns/:slug/users has rows.
        4.times do |i|
          student = create(:user, username: "Student#{i + 1}",
                                  real_name: "Sam Demo #{i + 1}")
          CoursesUsers.create!(user: student, course:,
                               role: CoursesUsers::Roles::STUDENT_ROLE,
                               revision_count: 5 + i,
                               character_sum_ms: 2_000 + (i * 1_500))
        end

        # Articles edited within the course → /campaigns/:slug/articles and
        # /tagged_courses/:tag/articles have rows.
        ['Common_loon', 'Pacific_loon', 'Yellow-billed_loon',
         'Black-throated_loon'].each_with_index do |title, i|
          article = create(:article, title:)
          create(:articles_course, article:, course:,
                                   character_sum: 1_500 * (i + 1),
                                   view_count: 300 * (i + 1),
                                   references_count: 4 * (i + 1))
        end

        # Alerts on the course → /campaigns/:slug/alerts and
        # /tagged_courses/:tag/alerts have rows.
        ArticlesForDeletionAlert.create!(course:,
                                         article: Article.first,
                                         message: 'Common_loon was nominated ' \
                                                  'for deletion at AfD.')
        UnsubmittedCourseAlert.create!(course:,
                                       message: 'Course was created but never ' \
                                                'submitted for approval.')
      end

      it 'admin index, settings, alerts, recent activity, status, etc' do
        login_as(admin, scope: :user)

        visit '/admin'
        shoot('admin_index')

        visit '/settings'
        shoot('admin_settings', wait: 2.0)

        visit '/alerts_list'
        shoot('admin_alerts_list', wait: 2.0)

        visit '/recent-activity'
        shoot('admin_recent_activity', wait: 2.0)

        visit '/tickets/dashboard'
        shoot('admin_tickets_dashboard', wait: 2.0)

        RequestedAccount.create!(course:, username: 'AspiringEditor1',
                                 email: 'asp1@demo.test')
        RequestedAccount.create!(course:, username: 'AspiringEditor2',
                                 email: 'asp2@demo.test')
        visit '/requested_accounts'
        shoot('admin_requested_accounts')

        visit '/status'
        shoot('admin_status')

        visit '/styleguide'
        shoot('admin_styleguide')

        visit '/mailer_previews'
        shoot('admin_mailer_previews')

        visit '/analytics'
        shoot('admin_analytics')

        visit '/usage'
        shoot('admin_usage')

        visit '/ai_tools'
        shoot('admin_ai_tools')

        # Needs title + assignment_id params; without them, the controller's
        # Wikipedia query NoMethodErrors on a nil response.
        article = Article.find_by(title: 'Common_loon') || create(:article, title: 'Common_loon')
        assignment = create(:assignment, course:, article:, article_title: 'Common_loon')
        visit "/revision_feedback?title=Common_loon&assignment_id=#{assignment.id}"
        shoot('admin_revision_feedback', wait: 3.0)

        # Controller raises NilClass#flat_map with no data. Seed enough rows to
        # span a date range with non-nil likelihoods.
        article = create(:article, title: 'Demo_article')
        3.times do |i|
          RevisionAiScore.create!(article:, wiki_id: 1,
                                  created_at: (3 - i).days.ago,
                                  avg_ai_likelihood: 0.1 + (i * 0.2),
                                  max_ai_likelihood: 0.3 + (i * 0.2))
        end
        visit '/revision_ai_scores_stats'
        shoot('admin_revision_ai_scores_stats', wait: 2.0)

        visit '/ai_edit_alerts_stats/select_campaign'
        shoot('admin_ai_edit_alerts_select')

        visit '/update_username'
        shoot('admin_update_username')

        visit '/timeslice_duration'
        shoot('admin_timeslice_duration')

        visit '/mass_email/term_recap'
        shoot('admin_mass_email_term_recap')

        # /users lists the most recently created instructors.
        3.times do |i|
          create(:instructor, username: "ProfDemo#{i + 1}",
                              real_name: "Professor Demo #{i + 1}",
                              email: "prof#{i + 1}@example.test")
        end
        visit '/users'
        shoot('admin_users_lookup')

        visit '/surveys'
        shoot('admin_surveys')

        visit '/surveys/new'
        shoot('admin_surveys_new')

        FeedbackFormResponse.create!(user_id: admin.id,
                                     subject: '/training/students/wikipedia-essentials',
                                     body: 'Helpful intro, but the section on ' \
                                           'reliable sources could use more examples.',
                                     created_at: 2.days.ago)
        FeedbackFormResponse.create!(user_id: admin.id,
                                     subject: 'Article finder',
                                     body: 'It would be great if the article ' \
                                           'finder could filter by article quality ' \
                                           'class out of the box.',
                                     created_at: 1.day.ago)
        FeedbackFormResponse.create!(user_id: admin.id,
                                     subject: 'Dashboard onboarding',
                                     body: 'The onboarding tour worked smoothly. ' \
                                           'Thanks!',
                                     created_at: 4.hours.ago)
        visit '/feedback_form_responses'
        shoot('admin_feedback_responses')

        visit '/copy_course'
        shoot('copy_course')

        visit '/training_module_drafts'
        shoot('admin_training_module_drafts', wait: 2.0)

        visit "/mass_enrollment/#{course.slug}"
        shoot('admin_mass_enrollment')

        visit '/faq/new'
        shoot('admin_faq_new')

        visit '/faq_topics'
        shoot('faq_topics_index')

        visit '/faq_topics/new'
        shoot('admin_faq_topic_new')
      end

      it 'tagged courses pages' do
        login_as(admin, scope: :user)

        visit "/tagged_courses/#{tag.tag}/programs"
        shoot('tagged_courses_programs', wait: 2.0)

        visit "/tagged_courses/#{tag.tag}/articles"
        shoot('tagged_courses_articles')

        visit "/tagged_courses/#{tag.tag}/alerts"
        shoot('tagged_courses_alerts', wait: 2.0)
      end

      it 'campaign pages' do
        login_as(admin, scope: :user)

        visit '/campaigns'
        shoot('campaigns_index', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/overview"
        shoot('campaign_overview', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/programs"
        shoot('campaign_programs', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/articles"
        shoot('campaign_articles', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/users"
        shoot('campaign_users')

        visit "/campaigns/#{campaign.slug}/alerts"
        shoot('campaign_alerts', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/ores_plot"
        shoot('campaign_ores_plot', wait: 2.0)

        visit "/campaigns/#{campaign.slug}/edit"
        shoot('campaign_edit')
      end
    end

    context 'wikidata stats display' do
      # Captures WikidataOverviewStats in both the campaign-overview embed and
      # the course-overview tab, in two flavors:
      #   * sparse — most counters are zero, only a handful of small non-zero
      #     values (mirrors a real campaign where a few students made a few
      #     edits on Wikidata)
      #   * rich — every section populated, sized like a multi-instructor
      #     Wikidata campaign that ran the full term
      #
      # All-zero stats are intentionally NOT covered: the course-overview tab
      # short-circuits when every counter is zero (overview_stats_tabs.jsx:37),
      # so an all-zero example wouldn't actually render the component.

      # Every key the WikidataOverviewStats component reads from `statistics`,
      # so we can build a sparse hash that includes the zeros the UI expects
      # (`renderZero={true}`) rather than letting any cell see undefined.
      # `'unknown'` is here for cross-branch portability: bin/inventory-diff
      # copies this spec into branches that may pre-date the
      # format_course_stats fix, where a missing `'unknown'` key plus a
      # zero `'other updates'` crashed the campaign JSON endpoint.
      WIKIDATA_STAT_KEYS = [
        'total revisions',
        'merged to', 'merged from', 'interwiki links added',
        'items created', 'items cleared',
        'claims created', 'claims changed', 'claims removed',
        'labels added', 'labels changed', 'labels removed',
        'descriptions added', 'descriptions changed', 'descriptions removed',
        'aliases added', 'aliases changed', 'aliases removed',
        'qualifiers added', 'references added', 'redirects created',
        'reverts performed', 'restorations performed', 'other updates',
        'lexeme items created', 'unknown'
      ].freeze

      let(:admin) { create(:super_admin) }
      let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

      let(:sparse_stats) do
        WIKIDATA_STAT_KEYS.to_h { |k| [k, 0] }
                          .merge('total revisions' => 11,
                                 'claims created' => 3,
                                 'labels added' => 4,
                                 'descriptions added' => 2)
      end

      let(:rich_stats) do
        {
          'total revisions' => 8_423,
          'merged to' => 12, 'merged from' => 12,
          'interwiki links added' => 219,
          'items created' => 437, 'items cleared' => 3,
          'claims created' => 5_812, 'claims changed' => 1_204, 'claims removed' => 86,
          'labels added' => 1_944, 'labels changed' => 220, 'labels removed' => 7,
          'descriptions added' => 1_310, 'descriptions changed' => 142,
          'descriptions removed' => 5,
          'aliases added' => 488, 'aliases changed' => 21, 'aliases removed' => 2,
          'qualifiers added' => 2_071, 'references added' => 3_402,
          'redirects created' => 18,
          'reverts performed' => 41, 'restorations performed' => 6, 'other updates' => 73,
          'lexeme items created' => 22, 'unknown' => 0
        }
      end

      it 'campaign and course overview, sparse and rich' do
        login_as(admin, scope: :user)

        variants = [
          { label: 'sparse', stats: sparse_stats,
            campaign_title: 'Wikidata Editing Demo (sparse)',
            campaign_slug: 'wikidata_demo_sparse',
            course_title: 'Wikidata Workshop — Light Activity',
            course_slug: 'Demo_University/Wikidata_Workshop_Light_(Spring_2025)',
            user_count: 4, recent_revision_count: 11 },
          { label: 'rich', stats: rich_stats,
            campaign_title: 'Wikidata Editing Demo (rich)',
            campaign_slug: 'wikidata_demo_rich',
            course_title: 'Wikidata Workshop — High Activity',
            course_slug: 'Demo_University/Wikidata_Workshop_Heavy_(Spring_2025)',
            user_count: 24, recent_revision_count: 642 }
        ]

        variants.each do |v|
          course = create(:course,
                          title: v[:course_title],
                          school: 'Demo University',
                          term: 'Spring 2025',
                          slug: v[:course_slug],
                          home_wiki_id: wikidata.id,
                          user_count: v[:user_count],
                          recent_revision_count: v[:recent_revision_count])
          CourseStat.create!(course:,
                             stats_hash: { 'www.wikidata.org' => v[:stats] })
          campaign = create(:campaign,
                            title: v[:campaign_title],
                            slug: v[:campaign_slug],
                            description: 'A demo campaign focused on Wikidata edits.')
          create(:campaigns_course, campaign:, course:)

          visit "/campaigns/#{campaign.slug}/overview"
          # Wait for the React-rendered CampaignStats widget before
          # snapshotting; otherwise the screenshot races the redux fetch of
          # /campaigns/:slug.json and the navbar shows an empty title.
          shoot("campaign_overview_wikidata_#{v[:label]}",
                wait: 1.0, wait_for: '#courses-count')

          visit "/courses/#{course.slug}/home"
          shoot("course_overview_wikidata_#{v[:label]}",
                wait: 1.5, wait_for: '.wikidata-stats-container')
        end
      end
    end

    context 'survey respondent walkthrough' do
      # Builds a survey with one of each major Rapidfire question type, then
      # walks the respondent through it, screenshotting each question as it's
      # revealed by the progress-stepper.
      #
      # Question setup mirrors `spec/features/surveys_spec.rb` — see there if
      # the rapidfire UI changes break this.

      it 'one of each question type, intro → questions → thanks' do
        instructor = create(:user, username: 'ProfRespondent')
        course = create(:course, title: 'Survey Demo Course',
                                 slug: 'Demo_University/Survey_Demo_Course_(2025)')
        article = create(:article, title: 'Common_loon')
        create(:articles_course, article:, course:)
        courses_user = create(:courses_user, user_id: instructor.id,
                                             course_id: course.id, role: 1)

        survey = create(:survey, name: 'Instructor Survey',
                                 intro: 'Welcome — share a few thoughts about ' \
                                        'how the course went and how the ' \
                                        'dashboard worked for you.',
                                 thanks: 'Thanks — your feedback helps us ' \
                                         'improve future terms!',
                                 open: true)
        question_group = create(:question_group, id: 1,
                                                 name: 'Course experience')
        survey.rapidfire_question_groups << question_group
        survey.save!

        # One question per type, in the order they'll appear.
        q_short = create(:q_short, question_group_id: question_group.id,
                                   question_text: 'What is your role in the course?')
        q_long = create(:q_long, question_group_id: question_group.id,
                                 question_text: 'Describe your experience ' \
                                                'teaching with the dashboard ' \
                                                'this term.')
        q_radio = create(:q_radio, question_group_id: question_group.id,
                                   answer_options: "Yes, very\r\nSomewhat\r\nNot really\r\n",
                                   question_text: 'Did the dashboard help your students?')
        checkbox_options = "Articles tab\r\nStudents tab\r\nTimeline\r\n" \
                           "Article Finder\r\nUploads\r\n"
        q_checkbox = create(:q_checkbox, question_group_id: question_group.id,
                                         answer_options: checkbox_options,
                                         question_text: 'Which dashboard features did you use?')
        select_options = "Wiki Education staff\r\nWikipedia volunteer\r\n" \
                         "Fellow instructor\r\nNobody\r\n"
        q_select = create(:q_select, question_group_id: question_group.id,
                                     answer_options: select_options,
                                     question_text: 'Who did you reach out to for support?')
        q_numeric = create(:q_numeric, question_group_id: question_group.id,
                                       question_text: 'How many hours per week ' \
                                                      'did you spend on this ' \
                                                      'Wikipedia assignment?')
        q_range = create(:q_rangeinput, question_group_id: question_group.id,
                                        question_text: 'Overall, rate your ' \
                                                       'experience with the dashboard.')
        # course_data Articles → checkbox of the articles edited in the course.
        q_articles = create(:q_checkbox, question_group_id: question_group.id,
                                         answer_options: '',
                                         course_data_type: 'Articles',
                                         question_text: 'Which of the assigned ' \
                                                        'articles were most ' \
                                                        'successful?')
        # Matrix-style block (same options, multiple rows).
        create(:matrix_question, question_text: 'Course planning was easy.',
                                 question_group_id: question_group.id)
        create(:matrix_question, question_text: 'Grading was straightforward.',
                                 question_group_id: question_group.id)
        create(:matrix_question, question_text: 'I will use the dashboard again.',
                                 question_group_id: question_group.id)

        # Loosen required-ness so the test can advance freely.
        [q_short, q_long, q_radio, q_checkbox, q_select, q_numeric, q_range,
         q_articles].each do |q|
          q.rules[:presence] = '0'
          q.save!
        end

        # Pin the id so admin_survey_assignments.png shows a stable "#N".
        survey_assignment = create(:survey_assignment, id: 1,
                                                       survey_id: survey.id,
                                                       courses_user_role: 1)
        create(:survey_notification, course_id: course.id,
                                     survey_assignment_id: survey_assignment.id,
                                     courses_users_id: courses_user.id)

        login_as(instructor, scope: :user)
        visit survey_path(survey)

        shoot('survey_intro', wait: 2.0)
        click_button 'Start'
        sleep 1

        shoot('survey_short', wait: 0.5)
        fill_in("answer_group_#{q_short.id}_answer_text", with: 'Instructor')
        within('div[data-progress-index="2"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_long', wait: 0.5)
        fill_in("answer_group_#{q_long.id}_answer_text",
                with: 'It was a productive term. Students engaged well with ' \
                      'the article-improvement workflow and the timeline kept ' \
                      'us on track.')
        within('div[data-progress-index="3"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_radio', wait: 0.5)
        find('.label', text: 'Yes, very').click
        within('div[data-progress-index="4"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_checkbox', wait: 0.5)
        find('.label', text: 'Articles tab').click
        find('.label', text: 'Article Finder').click
        within('div[data-progress-index="5"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_select', wait: 0.5)
        select 'Wiki Education staff',
               from: "answer_group_#{q_select.id}_answer_text"
        within('div[data-progress-index="6"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_numeric', wait: 0.5)
        fill_in("answer_group_#{q_numeric.id}_answer_text", with: '6')
        within('div[data-progress-index="7"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_range', wait: 0.5)
        within('div[data-progress-index="8"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_course_data_articles', wait: 0.5)
        within('div[data-progress-index="9"]') do
          click_button('Next', visible: true)
        end
        sleep 1

        shoot('survey_matrix', wait: 0.5)
        click_button('Submit Survey', visible: true)
        sleep 2

        shoot('survey_thanks', wait: 1.0)

        # Admin views of the survey ride along since the data is already set up.
        admin = create(:admin)
        login_as(admin, scope: :user)

        visit "/surveys/#{survey.id}/edit"
        shoot('admin_survey_edit', wait: 1.0)

        visit "/surveys/#{survey.id}/question_group"
        shoot('admin_survey_question_group', wait: 1.0)

        visit '/surveys/results'
        shoot('admin_surveys_results_index', wait: 1.0)

        visit '/survey/responses'
        shoot('admin_survey_responses', wait: 1.0)

        visit '/surveys/assignments'
        shoot('admin_survey_assignments', wait: 1.0)
      end
    end

    context 'user profiles & training' do
      let(:user) { create(:user) }

      it 'user profile and training library' do
        # Enroll the user in a couple of courses so the profile actually shows
        # something instead of "has not participated in any courses".
        course1 = create(:course,
                         title: 'Biology 101',
                         school: 'Demo University',
                         term: 'Fall 2024',
                         slug: 'Demo_University/Biology_101_(Fall_2024)',
                         start: 8.months.ago, end: 4.months.ago,
                         user_count: 18, character_sum: 32_000)
        course2 = create(:course,
                         title: 'Intro to Wikipedia Editing',
                         school: 'Demo University',
                         term: 'Spring 2025',
                         slug: 'Demo_University/Intro_to_Wikipedia_Editing_(Spring_2025)',
                         start: 30.days.ago, end: 120.days.from_now,
                         user_count: 12, character_sum: 24_500)
        CoursesUsers.create!(user:, course: course1,
                             role: CoursesUsers::Roles::STUDENT_ROLE)
        CoursesUsers.create!(user:, course: course2,
                             role: CoursesUsers::Roles::STUDENT_ROLE)

        login_as(user, scope: :user)

        visit "/users/#{user.username}"
        shoot('user_profile', wait: 2.0)

        visit '/training'
        shoot('training_index')
      end
    end
  end
end
