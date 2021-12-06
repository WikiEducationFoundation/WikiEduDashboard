# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/de_userfying_edit_alert_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe DeUserfyingEditAlertMonitor do
  let(:mntor) { described_class.new }
  let(:course1) { create(:course, slug: 'slug-one') }
  let(:course2) { create(:course, slug: 'slug-two') }
  let(:student1) { create(:user, username: 'alice', email: 'student1@example.edu') }
  let(:student2) { create(:user, username: 'bob', email: 'student2@example.edu') }
  let(:student3) { create(:user, username: 'carol', email: 'student3@example.edu') }
  let(:article1) { create(:article, title: 'my title 1', mw_page_id: 111) }
  let(:article2) { create(:article, title: 'my title 2', mw_page_id: 222) }
  let(:content_expert) { create(:user, greeter: true) }

  before do
    populate_students
  end

  describe '.edits' do
    it 'checks keys' do
      VCR.use_cassette 'recent_changes' do
        fedits = mntor.edits.first
        expect(fedits.dig('logparams', 'target_title')).not_to be_nil
        expect(fedits.dig('user')).not_to be_nil
        expect(fedits.dig('revid')).not_to be_nil
        expect(fedits.dig('pageid')).not_to be_nil
      end
    end
  end

  describe '.current_students' do
    it 'checks distinct enrolled students' do
      expect(mntor.current_students.count).to eq 3
    end
  end

  describe '.edits_made_by_students' do
    it 'filters students that de-userfyed their page' do
      allow(mntor).to receive(:edits).and_return(editsfeed)
      edits = mntor.edits
      students = mntor.current_students
      expect(mntor.edits_made_by_students(edits, students).count).to eq editsfeed.count
    end
  end

  describe '.create_alerts' do
    before do
      populate_content_expert
      populate_articles_courses
      allow(mntor).to receive(:edits).and_return(editsfeed)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
    end

    it 'emails a content expert per edit' do
      mntor.create_alerts
      expect(Alert.all.pluck(:email_sent_at).compact.count).to eq editsfeed.count
    end

    it 'does not create a third Alert' do
      Alert.create(type: 'DeUserfyingAlert',
                   course_id: course1.id,
                   article_id: article1.id,
                   revision_id: editsfeed.first['revid'])
      expect(Alert.count).to eq(1)
      mntor.create_alerts
      expect(Alert.count).to eq editsfeed.count
    end
  end

  private

  # Some students should be enrolled in multiple courses to make
  # the test effective.
  def populate_students
    student = CoursesUsers::Roles::STUDENT_ROLE
    courses_users = [
      { course_id: course1.id, user_id: student1.id, role: student },
      { course_id: course1.id, user_id: student3.id, role: student },
      { course_id: course2.id, user_id: student2.id, role: student },
      { course_id: course2.id, user_id: student3.id, role: student }
    ]
    CoursesUsers.create(courses_users)
  end

  def editsfeed
    [{ 'user' => 'alice', 'revid' => 12, 'pageid' => 111,
       'logparams' => { 'target_title' => 'my title 1' } },
     { 'user' => 'bob', 'revid' => 447, 'pageid' => 222,
       'logparams' => { 'target_title' => 'my title 2' } }]
  end

  def populate_content_expert
    create(:courses_user,
           user_id: content_expert.id,
           course_id: course1.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    create(:courses_user,
           user_id: content_expert.id,
           course_id: course2.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  def populate_articles_courses
    create(:articles_course, article_id: article1.id, course_id: course1.id)
    create(:articles_course, article_id: article2.id, course_id: course2.id)
  end
end
