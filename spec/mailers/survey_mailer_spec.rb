# frozen_string_literal: true
require 'rails_helper'

describe SurveyMailer, type: :mailer do
  describe '#notification' do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:course) { create(:course, id: 1) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) do
      create(:survey_assignment, survey_id: survey.id, courses_user_role: role,
                                 email_template: email_template)
    end
    let(:survey_notification) do
      create(:survey_notification,
             course_id: course.id,
             courses_users_id: courses_user.id,
             survey_assignment_id: survey_assignment.id)
    end

    let(:mail) { SurveyMailer.send_notification(survey_notification) }

    context 'when it is an instructor survey' do
      let(:role) { CoursesUsers::Roles::INSTRUCTOR_ROLE }
      let(:email_template) { 'instructor_survey' }
      it 'sends a personalized email to the instructor' do
        expect(mail.body.encoded).to match(user.username)
        expect(mail.subject).to match('A survey is available for your course')
        expect(mail.to).to eq([user.email])
      end
    end

    context 'when it is a student survey' do
      let(:role) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:email_template) { 'student_learning_preassessment' }
      it 'sends a personalized email about the student survey' do
        # expect(mail.body.encoded).to match(user.username)
        # expect(mail.subject).to match('A survey is available for your course')
        expect(mail.to).to eq([user.email])
      end
    end
  end

  describe '#follow_up' do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:course) { create(:course, id: 1) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) do
      create(:survey_assignment, survey_id: survey.id, courses_user_role: role,
                                 email_template: email_template)
    end
    let(:survey_notification) do
      create(:survey_notification,
             course_id: course.id,
             courses_users_id: courses_user.id,
             survey_assignment_id: survey_assignment.id)
    end

    let(:mail) { SurveyMailer.send_follow_up(survey_notification) }

    context 'when it is an instructor survey' do
      let(:role) { CoursesUsers::Roles::INSTRUCTOR_ROLE }
      let(:email_template) { 'instructor_survey' }
      it 'contains the correct user email and body' do
        expect(mail.body.encoded).to match(user.username)
        expect(mail.subject).to match('Reminder: A survey is available for your course')
        expect(mail.to).to eq([user.email])
      end
    end

    context 'when it is a student survey' do
      let(:role) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:email_template) { 'student_learning_preassessment' }
      it 'contains the correct user email and body' do
        # expect(mail.body.encoded).to match(user.username)
        # expect(mail.subject).to match('A survey is available for your course')
        expect(mail.to).to eq([user.email])
      end
    end
  end
end
