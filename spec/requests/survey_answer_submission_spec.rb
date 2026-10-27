# frozen_string_literal: true

require 'rails_helper'

describe 'Survey answer submission', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'submitting survey answers' do
    let(:survey) { create(:survey, open: false, closed: false) }
    let(:question_group) { create(:question_group, name: 'Group') }
    let!(:question) { create(:q_long, question_group_id: question_group.id) }
    let(:path) { "/surveys/rapidfire/question_groups/#{question_group.id}/answer_groups" }
    let(:params) { { answer_group: { question.id.to_s => { answer_text: 'An answer' } } } }

    before { survey.rapidfire_question_groups << question_group }

    def assign(survey, to:)
      course = create(:course, slug: "School/Course_#{to.id}_(term)")
      courses_user = create(:courses_user, course:, user: to,
                                           role: CoursesUsers::Roles::STUDENT_ROLE)
      survey_assignment = create(:survey_assignment, survey:, courses_user_role: 0)
      create(:survey_notification, courses_users_id: courses_user.id, course_id: course.id,
                                   survey_assignment_id: survey_assignment.id)
    end

    it 'is refused to a logged-out visitor' do
      post path, params:, as: :json
      expect(response.status).to eq(401)
      expect(Rapidfire::AnswerGroup.count).to eq(0)
    end

    it 'is refused to a signed-in user who is not assigned the survey' do
      login_as user
      post path, params:, as: :json
      expect(response.status).to eq(401)
      expect(Rapidfire::AnswerGroup.count).to eq(0)
    end

    it 'is refused for a closed survey, even to an assigned user' do
      assign(survey, to: user)
      survey.update(closed: true)
      login_as user
      post path, params:, as: :json
      expect(Rapidfire::AnswerGroup.count).to eq(0)
    end

    it 'is accepted from an assigned user' do
      assign(survey, to: user)
      login_as user
      post path, params:, as: :json
      expect(Rapidfire::AnswerGroup.last.user).to eq(user)
    end

    it 'is accepted from any signed-in user for an open survey' do
      survey.update(open: true)
      login_as user
      post path, params:, as: :json
      expect(Rapidfire::AnswerGroup.last.user).to eq(user)
    end
  end
end
