require 'rails_helper'
require "#{Rails.root}/lib/student_greeter"

describe StudentGreeter do
  describe '.greet_all_ungreeted_students' do
    subject { described_class.greet_all_ungreeted_students }

    before do
      create(:course, id: 1, start: 2.weeks.ago, end: Date.today + 2.weeks)
      create(:user, id: 1, wiki_id: 'Greeter', greeter: true)
      create(:courses_user, id: 1, course_id: 1, user_id: 1, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      create(:user, id: 2, wiki_id: 'Ungreeted Student')
      create(:courses_user, id: 2, course_id: 1, user_id: 2, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'posts greetings from Wiki Ed staff to students in their current courses' do
      stub_raw_action
      stub_contributors_query
      stub_oauth_edit

      subject
      expect(User.find(2).greeted).to eq(true)
    end

    it 'greets students with blank talk pages' do
      expect_any_instance_of(WikiApi).to receive(:get_page_content).and_return(nil)
      stub_oauth_edit

      subject
      expect(User.find(2).greeted).to eq(true)
    end

    it 'skips students who are already greeted' do
      User.find(2).update_attributes(greeted: true)
      allow_any_instance_of(WikiEdits).to receive(:get_tokens)
      expect_any_instance_of(WikiEdits).not_to receive(:get_tokens)
      subject
      expect(User.find(2).greeted).to eq(true)
    end

    it 'skips students whose talk pages have been edited by greeters, and marks them' do
      allow_any_instance_of(StudentGreeter).to receive(:ids_of_contributors_to_talk_page)
        .and_return([1])
      stub_raw_action

      allow_any_instance_of(WikiEdits).to receive(:get_tokens)
      expect_any_instance_of(WikiEdits).not_to receive(:get_tokens)
      subject
      expect(User.find(2).greeted).to eq(true)
    end

    it 'does nothing if no Wiki Ed staff are part of the course' do
      CoursesUsers.find(1).destroy
      subject
      expect(User.find(2).greeted).to eq(false)
    end
  end
end
