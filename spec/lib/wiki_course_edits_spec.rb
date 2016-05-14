require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_edits"

describe WikiCourseEdits do
  let!(:course) { create(:course, id: 1, submitted: true) }
  let(:user) { create(:user) }

  describe '#update_course' do
    it 'edits a Wikipedia page representing a course' do
      stub_oauth_edit
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user)
    end

    it 'edits the course page with the delete option' do
      stub_oauth_edit
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
    it 'posts to the userpage of the instructor and a noticeboard' do
      stub_oauth_edit
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top) # userpage edit
      expect_any_instance_of(WikiEdits).to receive(:add_new_section) # noticeboard edit
      WikiCourseEdits.new(action: :announce_course,
                          course:  course,
                          current_user: user,
                          instructor: nil) # defaults to current user
    end
  end

  describe '#enroll_in_course' do
    it 'posts to the userpage of the enrolling student and their sandbox' do
      stub_oauth_edit
      expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).twice
      WikiCourseEdits.new(action: :enroll_in_course,
                          course: course,
                          current_user: user)
    end
  end

  describe '#update_assignments' do
    let(:selfie) { create(:article, title: 'Selfie') }
    let(:selfie_talk) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }
    let(:redirect) { create(:article, title: 'Athletics_in_Epic_Poetry') }

    it 'updates talk pages and course page with assignment info' do
      stub_raw_action
      stub_oauth_edit
      allow_any_instance_of(WikiApi).to receive(:redirect?).and_return(false)
      expect_any_instance_of(WikiEdits).to receive(:post_whole_page).at_least(:once)
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
  end

  context 'for course types that do not make edits' do
    let(:visiting_scholarship) { create(:visiting_scholarship, submitted: true) }
    let(:editathon) { create(:editathon, submitted: true) }
    let(:legacy_course) { create(:legacy_course) }
    let(:basic_course) { create(:basic_course, submitted: true) }

    it 'returns immediately without making any edits' do
      expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
      WikiCourseEdits.new(action: :update_course,
                          course: visiting_scholarship,
                          current_user: user)
      WikiCourseEdits.new(action: :update_course,
                          course: editathon,
                          current_user: user)
      WikiCourseEdits.new(action: :update_assignments,
                          course: legacy_course,
                          current_user: user)
      WikiCourseEdits.new(action: :update_assignments,
                          course: basic_course,
                          current_user: user)
    end
  end
end
