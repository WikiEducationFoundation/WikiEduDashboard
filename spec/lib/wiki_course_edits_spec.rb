# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_edits"
require "#{Rails.root}/lib/errors/page_content_errors"

describe WikiCourseEdits do
  let(:home_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:slug) { 'Missouri_SandT/History_of_Science_(Fall_2019)' }
  let(:course) { create(:course, id: 1, submitted: true, home_wiki:, slug:) }
  let(:user) { create(:user) }
  let(:enrolling_user) { create(:user, username: 'Belajane41') }
  let(:disenrolling_user) { create(:user, username: 'Belajane41') }
  # rubocop:disable Layout/LineLength
  let(:user_page_content) do
    "{{dashboard.wikiedu.org student editor | course = [[Wikipedia:Wiki_Ed/Missouri_SandT/History_of_Science_(Fall_2019)]] | slug = Missouri_SandT/History_of_Science_(Fall_2019) }}\nAny other user page content"
  end
  let(:user_page_talk_content) do
    "{{dashboard.wikiedu.org talk course link | course = [[Wikipedia:Wiki_Ed/Missouri_SandT/History_of_Science_(Fall_2019)]] | slug = Missouri_SandT/History_of_Science_(Fall_2019) }}\nAny other user talk page content"
  end
  # rubocop:enable Layout/LineLength
  let(:user_template) { WikiUserpageOutput.new(course).enrollment_template }
  let(:talk_template) { WikiUserpageOutput.new(course).enrollment_talk_template }
  let(:sandbox_template) { WikiUserpageOutput.new(course).sandbox_template(ENV['dashboard_url']) }

  let(:user_page_content_without_enrollment) { '{{a user page content}}' }
  let(:user_talk_page_content_without_enrollment) { '{{a user talk page content}}' }

  before do
    stub_oauth_edit
  end

  describe '#update_course' do
    it 'edits a Wikipedia page representing a course' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      described_class.new(action: :update_course,
                          course:,
                          current_user: user)
    end

    it 'edits the course page with the delete option' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      described_class.new(action: :update_course,
                          course:,
                          current_user: user,
                          delete: true)
    end

    it 'reposts a clean version after hitting the spam filter' do
      stub_oauth_edit_spamblock # MediaWiki API returns an array of URL matches
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).twice.and_call_original
      described_class.new(action: :update_course,
                          course:,
                          current_user: user)
    end

    it 'reposts a clean version after hitting the spam filter with multiple matches' do
      stub_oauth_edit_spamblock_multiple # MediaWiki API returns a JSON object of URL matches
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).twice.and_call_original
      described_class.new(action: :update_course,
                          course:,
                          current_user: user)
    end
  end

  describe '#announce_course' do
    # Posts to the Wiki Education dashboard by default in tests
    it 'posts to the userpage of the instructor and a noticeboard' do
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top) # userpage edit
      expect_any_instance_of(WikiEdits).to receive(:add_new_section) # noticeboard edit
      described_class.new(action: :announce_course,
                          course:,
                          current_user: user,
                          instructor: nil) # defaults to current user
    end

    context 'makes correct edits on the Wiki Education Dashboard' do
      it 'posts to dashboard using correct templates' do
        expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
          .with('User:Ragesock',
                user,
                "{{course instructor | course = [[#{course.wiki_title}]] }}\n",
                "New course announcement: [[#{course.wiki_title}]].")
        described_class.new(action: :announce_course,
                            course:,
                            current_user: user,
                            instructor: nil)
      end
    end

    context 'when the course has no wiki page enabled' do
      let(:course) { create(:fellows_cohort, submitted: true) }

      it 'makes no edit' do
        expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
        described_class.new(action: :announce_course,
                            course:,
                            current_user: user,
                            instructor: nil)
      end
    end

    context 'makes correct edits on P&E Outreach Dashboard' do
      before do
        @dashboard_url = ENV['dashboard_url']
        ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
      end

      after do
        ENV['dashboard_url'] = @dashboard_url
      end

      context 'for enabled projects' do
        it 'posts to P&E Dashboard' do
          expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
          expect_any_instance_of(WikiEdits).to receive(:add_new_section)
          described_class.new(action: :announce_course,
                              course:,
                              current_user: user,
                              instructor: nil)
        end

        it 'posts to P&E Dashboard with correct template' do
          expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
            .with('User:Ragesock',
                  user,
                  "{{program instructor | course = [[#{course.wiki_title}]] }}\n",
                  "New course announcement: [[#{course.wiki_title}]].")
          described_class.new(action: :announce_course,
                              course:,
                              current_user: user,
                              instructor: nil)
        end
      end

      context 'for disabled projects' do
        before { stub_wiki_validation }

        let(:wiki) { create(:wiki, language: 'pt', project: 'wikipedia') }
        let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: wiki.id) }

        it 'does not post to P&E Dashboard' do
          expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
          expect_any_instance_of(WikiEdits).not_to receive(:add_new_section)
          described_class.new(action: :announce_course,
                              course:,
                              current_user: user,
                              instructor: nil)
        end
      end
    end
  end

  describe '#enroll_in_course' do
    it 'respects the enrollment_edits_enabled edit_settings flag' do
      course.update(flags: { 'edit_settings' => { 'enrollment_edits_enabled' => false } })
      expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
      described_class.new(action: :enroll_in_course,
                          course:,
                          current_user: user,
                          enrolling_user:)
    end
    # Posts to the Wiki Education dashboard by default in tests

    it 'posts to the userpage of the enrolling student and their sandbox' do
      expect(AddSandboxTemplate).to receive(:new)
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).twice
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('')
      described_class.new(action: :enroll_in_course,
                          course:,
                          current_user: user,
                          enrolling_user:)
    end

    it 'does not repost templates that are already present' do
      expect(AddSandboxTemplate).to receive(:new)
      expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
      allow_any_instance_of(WikiApi).to receive(:get_page_content)
        .and_return(user_page_content,
                    talk_template)
      described_class.new(action: :enroll_in_course,
                          course:,
                          current_user: user,
                          enrolling_user:)
    end

    context 'when get_page_content returns nil' do
      it 'raises a NilPageContentError' do
        allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(nil)
        expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
        expect do
          described_class.new(action: :enroll_in_course,
                              course:,
                              current_user: user,
                              enrolling_user:)
        end.to raise_error(Errors::PageContentErrors::NilPageContentError)
      end
    end

    context 'makes correct edits on P&E Outreach Dashboard' do
      unless Features.wiki_ed?
        before do
          @dashboard_url = ENV['dashboard_url']
          ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
        end

        after do
          ENV['dashboard_url'] = @dashboard_url
        end

        context 'for enabled projects' do
          it 'posts to P&E Dashboard' do
            # Only twice for outreachdashboard, for user page and talk page.
            # Sandbox templates are skipped for non-Wiki Ed edits.
            expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).twice
            described_class.new(action: :enroll_in_course,
                                course:,
                                current_user: user,
                                enrolling_user:)
          end
        end

        context 'for disabled projects' do
          before { stub_wiki_validation }

          let(:wiki) { create(:wiki, language: 'pt', project: 'wikipedia') }
          let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: wiki.id) }

          it 'does not post to P&E Dashboard' do
            expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
            described_class.new(action: :enroll_in_course,
                                course:,
                                current_user: user,
                                enrolling_user:)
          end
        end
      end
    end
  end

  describe '#disenroll_from_course' do
    it 'respects the enrollment_edits_enabled edit_settings flag' do
      course.update(flags: { 'edit_settings' => { 'enrollment_edits_enabled' => false } })
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(
        user_page_content,
        user_page_talk_content
      )
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      described_class.new(action: :disenroll_from_course,
                          course:,
                          current_user: user,
                          disenrolling_user:)
    end

    it 'does nothing if get_page_content returns nil' do
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(nil)
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      described_class.new(action: :disenroll_from_course,
                          course:,
                          current_user: user,
                          disenrolling_user:)
    end

    it 'does nothing if page content does not include templates' do
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(
        user_page_content_without_enrollment,
        user_talk_page_content_without_enrollment
      )
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      described_class.new(action: :disenroll_from_course,
                          course:,
                          current_user: user,
                          disenrolling_user:)
    end

    it 'removes enrollment template from user page if it exists' do
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(
        user_page_content,
        user_talk_page_content_without_enrollment
      )
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).with(
        user, 'User:Belajane41', 'Any other user page content',
        'User has disenrolled in [[Wikipedia:Wiki_Ed/Missouri_SandT/'\
        'History_of_Science_(Fall_2019)]].'
      )
      described_class.new(action: :disenroll_from_course,
                          course:,
                          current_user: user,
                          disenrolling_user:)
    end

    it 'removes enrollment template from user talk page if it exists' do
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(
        user_page_content_without_enrollment,
        user_page_talk_content
      )
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).with(
        user, 'User_talk:Belajane41', 'Any other user talk page content',
        'removing {{dashboard.wikiedu.org talk course link}}'
      )
      described_class.new(action: :disenroll_from_course,
                          course:,
                          current_user: user,
                          disenrolling_user:)
    end
  end

  describe '#update_assignments' do
    let(:instructor) { create(:user, username: 'Instructor') }
    let(:selfie) { create(:article, title: 'Selfie') }
    let(:selfie_talk) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }
    let(:redirect) { create(:article, title: 'Athletics_in_Epic_Poetry') }

    before do
      stub_wiki_validation
      stub_raw_action
      create(:courses_user, user:, course:)
      create(:courses_user, user: instructor, course:,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    context 'when the course is not yet approved for a campaign' do
      it 'does not make assignment edits' do
        expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
        create(:assignment,
               user_id: user.id,
               course_id: course.id,
               article_title: 'Selfie',
               article_id: selfie.id,
               role: Assignment::Roles::ASSIGNED_ROLE)
        create(:assignment,
               user_id: user.id,
               course_id: course.id,
               article_title: 'Talk:Selfie',
               article_id: selfie_talk.id,
               role: Assignment::Roles::REVIEWING_ROLE)
        described_class.new(action: :update_assignments,
                            course:,
                            current_user: user)
      end
    end

    context 'when the course is approved and in a campaign' do
      let(:campaign) { create(:campaign) }
      let!(:campaigns_course) do
        create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
      end

      context 'posts are made' do
        before do
          allow_any_instance_of(WikiApi).to receive(:redirect?).and_return(false)
          create(:assignment,
                 user_id: user.id,
                 course_id: course.id,
                 article_title: 'Selfie',
                 article_id: selfie.id,
                 role: Assignment::Roles::ASSIGNED_ROLE)
          create(:assignment,
                 user_id: user.id,
                 course_id: course.id,
                 article_title: 'Talk:Selfie',
                 article_id: selfie_talk.id,
                 role: Assignment::Roles::REVIEWING_ROLE)
        end

        # Posts to the Wiki Education dashboard by default in tests
        it 'updates talk pages and course page with assignment info' do
          expect_any_instance_of(WikiEdits).to receive(:post_whole_page).at_least(:once)
          described_class.new(action: :update_assignments,
                              course:,
                              current_user: user)
        end

        context 'makes correct edits on P&E Outreach Dashboard' do
          before do
            @dashboard_url = ENV['dashboard_url']
            ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
          end

          after do
            ENV['dashboard_url'] = @dashboard_url
          end

          context 'for enabled projects' do
            it 'posts to P&E Dashboard' do
              expect_any_instance_of(WikiEdits).to receive(:post_whole_page).at_least(:once)
              described_class.new(action: :update_assignments,
                                  course:,
                                  current_user: user)
            end
          end

          context 'for disabled projects' do
            let(:wiki) { Wiki.get_or_create(language: 'pt', project: 'wikipedia') }
            let(:course) { create(:course, submitted: true, home_wiki: wiki) }

            it 'does not post to P&E Dashboard' do
              expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
              described_class.new(action: :update_assignments,
                                  course:,
                                  current_user: user)
            end
          end
        end
      end

      context 'posts are not made' do
        it 'does not post if page is a redirect' do
          allow_any_instance_of(WikiApi).to receive(:redirect?).and_return(true)
          expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
          create(:assignment,
                 user_id: user.id,
                 course_id: course.id,
                 article_title: 'Athletics_in_Epic_Poetry',
                 article_id: redirect.id,
                 role: Assignment::Roles::ASSIGNED_ROLE)
          described_class.new(action: :update_assignments,
                              course:,
                              current_user: user)
        end

        it 'does not post if assignment has no article_id' do
          expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
          create(:assignment,
                 user_id: user.id,
                 course_id: course.id,
                 article_title: 'Selfie',
                 article_id: nil,
                 role: Assignment::Roles::ASSIGNED_ROLE)
          described_class.new(action: :update_assignments,
                              course:,
                              current_user: user)
        end

        it 'does not post if assignment is for instructor' do
          expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
          create(:assignment,
                 user_id: instructor.id,
                 course_id: course.id,
                 article_title: 'Selfie',
                 article_id: selfie.id,
                 role: Assignment::Roles::ASSIGNED_ROLE)
          described_class.new(action: :update_assignments,
                              course:,
                              current_user: user)
        end

        it 'does not post if assignment is an Available Article with no assigned user' do
          expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
          create(:assignment,
                 user_id: nil,
                 course_id: course.id,
                 article_title: 'Selfie',
                 article_id: selfie.id,
                 role: Assignment::Roles::ASSIGNED_ROLE)
          described_class.new(action: :update_assignments,
                              course:,
                              current_user: user)
        end
      end
    end

    context 'when an approved course is not on enwiki' do
      let(:home_wiki) { Wiki.get_or_create(language: 'pt', project: 'wikipedia') }
      let(:pt_selfie) { create(:article, wiki: home_wiki, title: 'Selfie') }
      let(:campaign) { create(:campaign) }
      let!(:campaigns_course) do
        create(:campaigns_course, campaign:, course:)
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('dashboard_url').and_return('outreachdashboard.wmflabs.org')
        create(:assignment,
               user:,
               course:,
               article_title: 'Selfie',
               article: pt_selfie,
               wiki: home_wiki,
               role: Assignment::Roles::ASSIGNED_ROLE)
      end

      it 'posts the template to the top of the page' do
        expect_any_instance_of(WikiEdits).to receive(:post_whole_page).at_least(:once)
        allow_any_instance_of(Wiki).to receive(:edits_enabled?).and_return(true)
        described_class.new(action: :update_assignments,
                            course:,
                            current_user: user)
      end
    end
  end

  context 'for course types that DO NOT make edits' do
    let(:visiting_scholarship) { create(:visiting_scholarship, submitted: true) }
    let(:editathon) { create(:editathon, submitted: true) }
    let(:legacy_course) { create(:legacy_course) }

    it 'returns immediately without making any edits' do
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      described_class.new(action: :update_course,
                          course: visiting_scholarship,
                          current_user: user)
      described_class.new(action: :update_course,
                          course: editathon,
                          current_user: user)
      described_class.new(action: :update_course,
                          course: legacy_course,
                          current_user: user)
    end
  end

  context 'for course types that do not make assignment edits' do
    let(:fellows_cohort) { create(:fellows_cohort) }

    it 'returns immediately with assignment-related edit actions' do
      expect_any_instance_of(described_class).not_to receive(:update_assignments)
      expect_any_instance_of(described_class).not_to receive(:remove_assignment)
      described_class.new(action: :update_assignments,
                          course: fellows_cohort,
                          current_user: user)
      described_class.new(action: :remove_assignment,
                          course: fellows_cohort,
                          current_user: user,
                          assignment: nil)
    end
  end

  context 'for course types that DO make edits' do
    let(:basic_course) { create(:basic_course, submitted: true) }

    it 'makes edits' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      described_class.new(action: :update_course,
                          course: basic_course,
                          current_user: user)
    end
  end
end
