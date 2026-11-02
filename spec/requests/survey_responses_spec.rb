# frozen_string_literal: true

require 'rails_helper'

# The recent-responses list shows who answered each survey, which for a
# confidential survey is confidential too.
describe 'Recent survey responses', type: :request do
  let(:confidential_survey) { create(:survey, confidential_results: true) }
  let(:open_survey) { create(:survey, name: 'Open survey') }
  let(:confidential_group) { create(:question_group, name: 'Confidential group') }
  let(:open_group) { create(:question_group, name: 'Open group') }

  before do
    confidential_survey.rapidfire_question_groups << confidential_group
    open_survey.rapidfire_question_groups << open_group
    Rapidfire::AnswerGroup.create!(question_group: confidential_group,
                                   user: create(:user, username: 'ConfidentialRespondent'))
    Rapidfire::AnswerGroup.create!(question_group: open_group,
                                   user: create(:user, username: 'OpenRespondent'))
    # Answers submitted before user checks existed can have no user.
    Rapidfire::AnswerGroup.create!(question_group: open_group, user: nil)
  end

  it 'leaves out confidential surveys for an admin who is not a super admin' do
    login_as create(:admin)
    get '/survey/responses'
    expect(response.status).to eq(200)
    expect(response.body).to include('OpenRespondent')
    expect(response.body).not_to include('ConfidentialRespondent')
  end

  it 'still lists other responses when a confidential survey has a blank question group row' do
    SurveysQuestionGroup.create!(survey: confidential_survey, rapidfire_question_group_id: nil)
    login_as create(:admin)
    get '/survey/responses'
    expect(response.body).to include('OpenRespondent')
  end

  it 'lists every response for a super admin' do
    login_as create(:super_admin)
    get '/survey/responses'
    expect(response.status).to eq(200)
    expect(response.body).to include('ConfidentialRespondent')
  end
end
