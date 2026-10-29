# frozen_string_literal: true

require 'rails_helper'

# Rapidfire question groups used for Scholars & Scientists applications are
# protected in the survey admin (config/initializers/surveys.rb): their answers
# would lose their questions if they were deleted, and they are kept out of
# surveys so their answers come only from applications.
describe 'Question groups used for course applications', type: :request do
  let(:course) { create(:fellows_cohort) }
  let(:question_group) { create(:question_group, name: 'Application questions') }
  let(:question) { create(:q_long, question_group_id: question_group.id) }

  before { login_as create(:admin) }

  def answer_in_an_application
    application = CourseApplication.create!(course:, user: create(:user))
    answer_group = Rapidfire::AnswerGroup.create!(question_group:, user: application.user,
                                                  course_application: application)
    Rapidfire::Answer.create!(answer_group:, question:, answer_text: 'An answer')
  end

  describe 'deleting a question group' do
    it 'is refused while the group is on a course form' do
      CourseApplicationForm.create!(course:, question_group_ids: [question_group.id])
      delete "/surveys/rapidfire/question_groups/#{question_group.id}"
      expect(response).to have_http_status(:conflict)
      expect(Rapidfire::QuestionGroup.exists?(question_group.id)).to be true
    end

    it 'is refused once applications have answered it, even off every form' do
      answer_in_an_application
      delete "/surveys/rapidfire/question_groups/#{question_group.id}"
      expect(response).to have_http_status(:conflict)
      expect(Rapidfire::QuestionGroup.exists?(question_group.id)).to be true
    end

    it 'is allowed for a group applications have never used' do
      delete "/surveys/rapidfire/question_groups/#{question_group.id}"
      expect(Rapidfire::QuestionGroup.exists?(question_group.id)).to be false
    end

    it 'is not offered on the edit page while refused' do
      CourseApplicationForm.create!(course:, question_group_ids: [question_group.id])
      get "/surveys/rapidfire/question_groups/#{question_group.id}/edit"
      expect(response.body).not_to include('Delete Question Group')
    end
  end

  describe 'deleting a question' do
    let(:question_path) do
      "/surveys/rapidfire/question_groups/#{question_group.id}/questions/#{question.id}"
    end

    it 'is refused once applications have answered it' do
      answer_in_an_application
      delete question_path
      expect(response).to have_http_status(:conflict)
      expect(Rapidfire::Question.exists?(question.id)).to be true
    end

    it 'is allowed for an unanswered question on a form' do
      CourseApplicationForm.create!(course:, question_group_ids: [question_group.id])
      delete question_path
      expect(Rapidfire::Question.exists?(question.id)).to be false
    end
  end

  it 'keeps groups on course forms off the survey question group picker' do
    CourseApplicationForm.create!(course:, question_group_ids: [question_group.id])
    create(:question_group, name: 'Survey questions')
    survey = create(:survey)
    get "/surveys/#{survey.id}/question_group"
    expect(response.body).to include('Survey questions')
    expect(response.body).not_to include('Application questions')
  end
end
