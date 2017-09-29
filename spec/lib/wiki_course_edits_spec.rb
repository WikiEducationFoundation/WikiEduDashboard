# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_edits"

describe WikiCourseEdits do
  let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: 1) }
  let(:user) { create(:user) }
  let(:enrolling_user) { create(:user, username: 'EnrollingUser') }

  before :each do
    stub_oauth_edit
  end

  describe '#update_course' do
    it 'edits a Wikipedia page representing a course' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user)
    end

    it 'edits the course page with the delete option' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user,
                          delete: true)
    end

    it 'reposts a clean version after hitting the spamblacklist' do
      stub_oauth_edit_spamblacklist
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).twice.and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user)
    end
  end

  describe '#announce_course' do
    # Posts to the Wiki Education dashboard by default in tests
    it 'posts to the userpage of the instructor and a noticeboard' do
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top) # userpage edit
      expect_any_instance_of(WikiEdits).to receive(:add_new_section) # noticeboard edit
      WikiCourseEdits.new(action: :announce_course,
                          course:  course,
                          current_user: user,
                          instructor: nil) # defaults to current user
    end

    context 'makes correct edits on the Wiki Education Dashboard' do
      it 'posts to dashboard using correct templates' do
        expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
          .with('User:Ragesock',
                user,
                "{{course instructor|course = [[#{course.wiki_title}]] }}\n",
                "New course announcement: [[#{course.wiki_title}]].")
        WikiCourseEdits.new(action: :announce_course,
                            course:  course,
                            current_user: user,
                            instructor: nil)
      end
    end

    context 'makes correct edits on P&E Outreach Dashboard' do
      before :each do
        @dashboard_url = ENV['dashboard_url']
        ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
      end

      after :each do
        ENV['dashboard_url'] = @dashboard_url
      end

      context 'for enabled projects' do
        it 'posts to P&E Dashboard' do
          expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
          expect_any_instance_of(WikiEdits).to receive(:add_new_section)
          WikiCourseEdits.new(action: :announce_course,
                              course:  course,
                              current_user: user,
                              instructor: nil)
        end

        it 'posts to P&E Dashboard with correct template' do
          expect_any_instance_of(WikiEdits).to receive(:add_to_page_top)
            .with('User:Ragesock',
                  user,
                  "{{program instructor|course = [[#{course.wiki_title}]] }}\n",
                  "New course announcement: [[#{course.wiki_title}]].")
          WikiCourseEdits.new(action: :announce_course,
                              course:  course,
                              current_user: user,
                              instructor: nil)
        end
      end

      context 'for disabled projects' do
        before { stub_wiki_validation }
        let(:wiki) { create(:wiki, language: 'pt', project: 'wikipedia') }
        let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: wiki.id) }

        it 'does not post to P&E Dashboard' do
          expect_any_instance_of(WikiEdits).to_not receive(:add_to_page_top)
          expect_any_instance_of(WikiEdits).to_not receive(:add_new_section)
          WikiCourseEdits.new(action: :announce_course,
                              course:  course,
                              current_user: user,
                              instructor: nil)
        end
      end
    end
  end

  describe '#enroll_in_course' do
    # Posts to the Wiki Education dashboard by default in tests
    it 'posts to the userpage of the enrolling student and their sandbox' do
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).thrice
      WikiCourseEdits.new(action: :enroll_in_course,
                          course: course,
                          current_user: user,
                          enrolling_user: enrolling_user)
    end

    context 'makes correct edits on P&E Outreach Dashboard' do
      before :each do
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
          WikiCourseEdits.new(action: :enroll_in_course,
                              course: course,
                              current_user: user,
                              enrolling_user: enrolling_user)
        end
      end

      context 'for disabled projects' do
        before { stub_wiki_validation }
        let(:wiki) { create(:wiki, language: 'pt', project: 'wikipedia') }
        let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: wiki.id) }

        it 'does not post to P&E Dashboard' do
          expect_any_instance_of(WikiEdits).to_not receive(:add_to_page_top)
          WikiCourseEdits.new(action: :enroll_in_course,
                              course: course,
                              current_user: user,
                              enrolling_user: enrolling_user)
        end
      end
    end
  end

  describe '#update_assignments' do
    before { stub_wiki_validation }
    let(:selfie) { create(:article, title: 'Selfie') }
    let(:selfie_talk) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }
    let(:redirect) { create(:article, title: 'Athletics_in_Epic_Poetry') }

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
        WikiCourseEdits.new(action: :update_assignments,
                            course: course,
                            current_user: user)
      end
    end

    context 'when the course is approved and in a campaign' do
      let(:campaign) { create(:campaign) }
      let!(:campaigns_course) do
        create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
      end

      context 'posts are made' do
        before :each do
          stub_raw_action
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
          WikiCourseEdits.new(action: :update_assignments,
                              course: course,
                              current_user: user)
        end

        context 'makes correct edits on P&E Outreach Dashboard' do
          before :each do
            @dashboard_url = ENV['dashboard_url']
            ENV['dashboard_url'] = 'outreachdashboard.wmflabs.org'
          end

          after do
            ENV['dashboard_url'] = @dashboard_url
          end

          context 'for enabled projects' do
            it 'posts to P&E Dashboard' do
              expect_any_instance_of(WikiEdits).to receive(:post_whole_page).at_least(:once)
              WikiCourseEdits.new(action: :update_assignments,
                                  course: course,
                                  current_user: user)
            end
          end

          context 'for disabled projects' do
            let(:wiki) { Wiki.get_or_create(language: 'pt', project: 'wikipedia') }
            let(:course) { create(:course, submitted: true, home_wiki_id: wiki.id) }

            it 'does not post to P&E Dashboard' do
              expect_any_instance_of(WikiEdits).to_not receive(:post_whole_page)
              WikiCourseEdits.new(action: :update_assignments,
                                  course: course,
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
          WikiCourseEdits.new(action: :update_assignments,
                              course: course,
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
          WikiCourseEdits.new(action: :update_assignments,
                              course: course,
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
          WikiCourseEdits.new(action: :update_assignments,
                              course: course,
                              current_user: user)
        end
      end
    end
  end

  context 'for course types that DO NOT make edits' do
    let(:visiting_scholarship) { create(:visiting_scholarship, submitted: true) }
    let(:editathon) { create(:editathon, submitted: true) }
    let(:legacy_course) { create(:legacy_course) }

    it 'returns immediately without making any edits' do
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      WikiCourseEdits.new(action: :update_course,
                          course: visiting_scholarship,
                          current_user: user)
      WikiCourseEdits.new(action: :update_course,
                          course: editathon,
                          current_user: user)
      WikiCourseEdits.new(action: :update_course,
                          course: legacy_course,
                          current_user: user)
    end
  end

  context 'for course types that DO make edits' do
    let(:basic_course) { create(:basic_course, submitted: true) }

    it 'makes edits' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: basic_course,
                          current_user: user)
    end
  end
end
