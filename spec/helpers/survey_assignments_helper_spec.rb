# frozen_string_literal: true

require 'rails_helper'

describe SurveyAssignmentsHelper, type: :helper do
  describe '#role_name_by_id' do
    it 'returns the role name in lowercase and in singular form' do
      expect(role_name_by_id(1)).to eq('instructor')
      expect(role_name_by_id(0)).to eq('student')
    end
  end
end
