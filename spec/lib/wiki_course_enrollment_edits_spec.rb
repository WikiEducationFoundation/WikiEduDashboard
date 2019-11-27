# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_enrollment_edits"

describe WikiCourseEnrollmentEdits do
  let(:slug) { 'Missouri_SandT/History_of_Science_(Fall_2019)' }
  let(:course) { create(:course, id: 1, submitted: true, home_wiki_id: 1, slug: slug) }
  let(:user) { create(:user) }
  let(:enrolling_user) { create(:user, username: 'Belajane41') }
  let(:disenrolling_user) { create(:user, username: 'UserToBeDisenrolled') }
  # rubocop:disable Metrics/LineLength
  let(:user_page_content) do
    '{{dashboard.wikiedu.org student editor | course = [[Wikipedia:Wiki_Ed/Missouri_SandT/History_of_Science_(Fall_2019)]] | slug = Missouri_SandT/History_of_Science_(Fall_2019) }}'
  end
  # rubocop:enable Metrics/LineLength
  let(:user_template) { WikiUserpageOutput.new(course).enrollment_template }
  let(:talk_template) { WikiUserpageOutput.new(course).enrollment_talk_template }
  let(:sandbox_template) { WikiUserpageOutput.new(course).sandbox_template(ENV['dashboard_url']) }

  before do
    stub_oauth_edit
  end

  describe '#enroll_in_course' do
    it 'respects the enrollment_edits_enabled edit_settings flag' do
      course.update(flags: { 'edit_settings' => { 'enrollment_edits_enabled' => false } })
      expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
      described_class.new(action: :enroll_in_course,
                          course: course,
                          current_user: user,
                          enrolling_user: enrolling_user)
    end
    # Posts to the Wiki Education dashboard by default in tests

    it 'posts to the userpage of the enrolling student and their sandbox' do
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).thrice
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('')
      described_class.new(action: :enroll_in_course,
                          course: course,
                          current_user: user,
                          enrolling_user: enrolling_user)
    end

    it 'does not repost templates that are already present' do
      expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
      allow_any_instance_of(WikiApi).to receive(:get_page_content)
        .and_return(user_page_content,
                    talk_template,
                    sandbox_template)
      described_class.new(action: :enroll_in_course,
                          course: course,
                          current_user: user,
                          enrolling_user: enrolling_user)
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
            expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
            described_class.new(action: :enroll_in_course,
                                course: course,
                                current_user: user,
                                enrolling_user: enrolling_user)
          end
        end
      end
    end
  end

  describe '#disenroll_from_course' do
    it 'respects the enrollment_edits_enabled edit_settings flag' do
      course.update(flags: { 'edit_settings' => { 'enrollment_edits_enabled' => false } })
      expect_any_instance_of(WikiApi).not_to receive(:get_page_content)
      described_class.new(action: :disenroll_from_course,
                          course: course,
                          current_user: user,
                          disenrolling_user: disenrolling_user)
    end

    it 'removes from the userpage of the disenrolling student and their sandbox' do
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).twice
      allow_any_instance_of(WikiApi).to receive(:get_page_content)
        .and_return(user_page_content,
                    talk_template)
      described_class.new(action: :disenroll_from_course,
                          course: course,
                          current_user: user,
                          disenrolling_user: disenrolling_user)
    end

    it 'does not remove templates that are not already present' do
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('')
      described_class.new(action: :disenroll_from_course,
                          course: course,
                          current_user: user,
                          disenrolling_user: disenrolling_user)
    end
  end
end
