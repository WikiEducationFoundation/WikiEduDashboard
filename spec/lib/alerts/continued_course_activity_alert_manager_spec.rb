# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/continued_course_activity_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ContinuedCourseActivityAlertManager do
  let(:course) { create(:course, start: 1.month.ago, end: 5.days.ago) }
  let(:user) { create(:user) }
  let(:article) { create(:article, namespace: Article::Namespaces::MAINSPACE) }
  let(:revision) do
    create(:revision, characters: character_count, date: revision_date,
                      article_id: article.id, user_id: user.id)
  end
  let(:subject) { ContinuedCourseActivityAlertManager.new([course]) }
  # Only Wikipedia Expert, indicated by greeter: true, should get emails.
  let(:admin) { create(:admin, email: 'staff@wikiedu.org', greeter: true) }

  before do
    create(:courses_user, user_id: user.id, course_id: course.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user,
           course_id: course.id,
           user_id: admin.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  context 'when there are no revisions after the course ends' do
    let(:character_count) { 5000 }
    let(:revision_date) { course.end - 2.days }
    it 'does not create an alert' do
      revision
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when there is only a small contribution after the course ends' do
    let(:character_count) { 5 }
    let(:revision_date) { course.end + 2.days }
    it 'does not create an alert' do
      revision
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when there is significant after the course ends' do
    let(:character_count) { 5000 }
    let(:revision_date) { course.end + 2.days }

    it 'creates an alert' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      revision
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end

    it 'should not create alert for the second time' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      revision
      subject.create_alerts

      # Attempt to create for the second time
      subject.create_alerts

      expect(Alert.count).to eq(1)
    end

    it 'should create another alert if the first alert is resolved' do
      revision
      subject.create_alerts

      Alert.first.update_attribute(:resolved, true)

      subject.create_alerts

      expect(Alert.count).to eq(2)
    end
  end
end
