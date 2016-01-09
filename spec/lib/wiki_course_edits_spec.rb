require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_edits"

describe WikiCourseEdits do
  let(:course) { create(:course) }
  let(:user) { create(:user) }

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
