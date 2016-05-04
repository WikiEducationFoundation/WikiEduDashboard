require 'rails_helper'

describe SurveyAssignmentsController do
  describe '#create' do
    let(:follow_up)  { 7 }
    let(:send_days)  { 7 }
    let(:survey)     { create(:survey) }
    let(:cohort)     { create(:cohort) }
    let(:instructor) { 1 }
    let(:admin)      { create(:admin) }
    let(:post_params) {{
      survey_assignment: {
        survey_id: survey.id,
        cohort_ids: cohort.id,
        courses_user_role: instructor,
        send_date_days: send_days,
        send_before: false,
        send_date_relative_to: "end",
        follow_up_days_after_first_notification: follow_up,
        published: true,
        notes: "foo",
      }
    }}
    before { allow(controller).to receive(:current_user).and_return(admin) }
    it 'allows create' do
      post :create, post_params
      expect(SurveyAssignment.last.follow_up_days_after_first_notification).to eq(follow_up)
    end
  end
end
