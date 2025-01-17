# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/continued_course_activity_alert_manager"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe ContinuedCourseActivityAlertManager do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:subject) { described_class.new([course]) }
  # Only Wikipedia Expert, indicated by greeter: true, should get emails.
  let(:admin) { create(:admin, email: 'staff@wikiedu.org', greeter: true) }
  let(:contribution) do
    { 'userid' => 4543197, 'user' => 'Ragesock', 'pageid' => 38467785, 'revid' => 882417897,
      'parentid' => 866599474, 'ns' => 0, 'title' => 'Jazz Workshop',
      'timestamp' => '2019-02-08T22:58:37Z', 'comment' => 'Fixed grammar', 'size' => 1920 }
  end
  let(:response) { instance_double(MediawikiApi::Response, data: content) }

  before do
    create(:courses_user, user_id: user.id, course_id: course.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user,
           course_id: course.id,
           user_id: admin.id,
           role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    allow_any_instance_of(WikiApi).to receive(:query).and_return response
  end

  context 'when there are no revisions after the course ends' do
    let(:content) { { 'usercontribs' => [] } }

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when there is only a small contribution after the course ends' do
    let(:content) do
      { 'usercontribs' => [contribution] }
    end

    it 'does not create an alert' do
      subject.create_alerts
      expect(Alert.count).to eq(0)
    end
  end

  context 'when there is significant after the course ends' do
    let(:content) do
      { 'usercontribs' => Array.new(21) { |_| contribution } }
    end

    it 'creates an alert' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      subject.create_alerts
      expect(Alert.count).to eq(1)
    end

    it 'does not create alert for the second time' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      subject.create_alerts

      # Attempt to create for the second time
      subject.create_alerts

      expect(Alert.count).to eq(1)
    end

    it 'creates another alert if the first alert is resolved' do
      subject.create_alerts

      Alert.first.update(resolved: true)

      subject.create_alerts

      expect(Alert.count).to eq(2)
    end
  end
end
