require 'rails_helper'

describe SurveyMailer, type: :mailer do
  describe '#notification' do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:course) { create(:course, id: 1) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) { create(:survey_assignment, survey_id: survey.id) }
    let(:survey_notification) do
      create(:survey_notification,
             course_id: course.id,
             courses_users_id: courses_user.id,
             survey_assignment_id: survey_assignment.id)
    end

    let(:mail) { SurveyMailer.notification(survey_notification).deliver_now }

    it 'sends a personalized email to the user' do
      expect(mail.body.encoded).to match(user.username)
      expect(mail.to).to eq([user.email])
    end
  end

  describe '#follow_up' do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:course) { create(:course, id: 1) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:survey) { create(:survey) }
    let(:survey_assignment) { create(:survey_assignment, survey_id: survey.id) }
    let(:survey_notification) do
      create(:survey_notification,
             course_id: course.id,
             courses_users_id: courses_user.id,
             survey_assignment_id: survey_assignment.id)
    end

    let(:mail) { SurveyMailer.follow_up(survey_notification).deliver_now }

    it 'contains the correct user email and body' do
      expect(mail.body.encoded).to match(user.username)
      expect(mail.to).to eq([user.email])
    end
  end
end
