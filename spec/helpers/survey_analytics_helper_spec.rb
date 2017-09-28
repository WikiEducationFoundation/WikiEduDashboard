# frozen_string_literal: true

require 'rails_helper'

describe SurveysAnalyticsHelper, type: :helper do
  describe '#assignment_response' do
    before do
      @survey_assignment = create(:survey_assignment)
      @survey_assignment.survey_notifications << create(:survey_notification, survey_assignment_id: @survey_assignment.id, completed: true)
      @survey_assignment.survey_notifications << create(:survey_notification, survey_assignment_id: @survey_assignment.id, completed: false)
      @survey_assignment.survey_notifications << create(:survey_notification, survey_assignment_id: @survey_assignment.id, completed: false)
    end
    it 'returns a string summarizing the response rate of a survey assignment' do
      expect(assignment_response(@survey_assignment)).to eq('33.33% (1/3)')
    end
  end
end
