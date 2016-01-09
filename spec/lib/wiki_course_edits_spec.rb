require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_edits"

describe WikiCourseEdits do
  let(:course) { create(:course, submitted: true) }
  let(:user) { create(:user) }

  describe '#update_course' do
    it 'should edit a Wikipedia page representing a course' do
      stub_oauth_edit
      expect(WikiEdits).to receive(:post_whole_page).twice.and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user)
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user,
                          delete: true)
    end

    it 'should repost a clean version after hitting the spamblacklist' do
      stub_oauth_edit_spamblacklist
      expect(WikiEdits).to receive(:post_whole_page).twice.and_call_original
      WikiCourseEdits.new(action: :update_course,
                          course: course,
                          current_user: user)
    end
  end

  describe '#announce_course' do
    it 'should post to the userpage of the instructor and a noticeboard' do
      stub_oauth_edit
      expect(WikiEdits).to receive(:add_to_page_top) # userpage edit
      expect(WikiEdits).to receive(:add_new_section) # noticeboard edit
      WikiCourseEdits.new(action: :announce_course,
                          course:  course,
                          current_user: user,
                          instructor: nil) # defaults to current user
    end
  end

  describe '#enroll_in_course' do
    it 'should post to the userpage of the enrolling student and their sandbox' do
      stub_oauth_edit
      expect(WikiEdits).to receive(:add_to_page_top).twice
      WikiCourseEdits.new(action: :enroll_in_course,
                          course: course,
                          current_user: user)
    end
  end
end
