# frozen_string_literal: true
# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

require 'rails_helper'

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

# An alert has a subject_id that can refer to any model, depending on the type.
# Here we create the subject record for the types that require one.
def alert_subject(alert_type)
  case alert_type
  when 'SurveyResponseAlert'
    create(:q_checkbox)
  end
end

describe Alert do
  let(:article) { create(:article) }
  let(:course) { create(:course) }
  let(:revision) { create(:revision) }
  let(:user) { create(:user) }
  let(:alert) { create(:alert, type: 'ArticlesForDeletionAlert', resolved: false) }
  let(:active_course_alert) { create(:active_course_alert) }
  let(:admin) { create(:admin) }

  describe 'abstract parent class' do
    it 'raises errors for required template methods' do
      alert = Alert.new
      expect { alert.main_subject }.to raise_error(NotImplementedError)
      expect { alert.url }.to raise_error(NotImplementedError)
    end
  end

  describe 'types' do
    it 'all implement #main_subject' do
      Alert::ALERT_TYPES.each do |type|
        Alert.create(type: type,
                     article: article,
                     course: course,
                     revision: revision,
                     user: user,
                     subject_id: alert_subject(type)&.id)
        expect(Alert.last.main_subject).to be_a(String)
      end
    end

    it 'all implement #url' do
      Alert::ALERT_TYPES.each do |type|
        Alert.create(type: type,
                     article_id: article.id,
                     course_id: course.id,
                     revision_id: revision.id,
                     user_id: user.id)
        expect(Alert.last.url).to be_a(String)
      end
    end

    it 'should be resolvable for resolvable alert types' do
      Alert::RESOLVABLE_ALERT_TYPES.each do |type|
        # Equals to ArticlesForDeletionAlert.new
        alert = type.constantize.new

        expect(alert.resolvable?).to be(true)
      end
    end

    it 'should not be resolvable for certain types' do
      unresolvable_alert_types =
        Alert::ALERT_TYPES - Alert::RESOLVABLE_ALERT_TYPES

      unresolvable_alert_types.each do |type|
        alert = type.constantize.new

        expect(alert.resolvable?).to be(false)
      end
    end

    it 'should not be resolvable if already resolved' do
      alert.update resolved: true
      expect(alert.resolvable?).to be(false)
    end
  end

  describe 'sending emails' do
    before { ENV['ProductiveCourseAlert_emails_disabled'] = 'true' }
    after { ENV['ProductiveCourseAlert_emails_disabled'] = 'false' }

    it 'can be disabled for a single alert type' do
      expect(AlertMailer).not_to receive(:alert)
      Alert.create(type: 'ProductiveCourseAlert',
                   article_id: article.id,
                   course_id: course.id,
                   revision_id: revision.id,
                   user_id: user.id,
                   target_user_id: user.id)
      Alert.last.email_content_expert
      Alert.last.email_course_admins
      Alert.last.email_target_user
    end

    it 'still sends emails for other alert types' do
      expect_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      create(:courses_user, course: course, user: admin,
                            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      Alert.create(type: 'ActiveCourseAlert',
                   article_id: article.id,
                   course_id: course.id,
                   revision_id: revision.id,
                   user_id: user.id,
                   target_user_id: user.id)
      Alert.last.email_course_admins
    end
  end
end
