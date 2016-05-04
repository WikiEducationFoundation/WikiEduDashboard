require 'rails_helper'

describe Survey do
  before(:each) do
    @survey = create(:survey)
    @survey.rapidfire_question_groups << create(:question_group)
  end

  describe 'scopes' do
    it 'has and belongs to many QuestionGroups' do
      expect(@survey.rapidfire_question_groups.length).to eq(1)
    end
  end

  describe '#status' do
    context 'when there are no active survey assignments' do
      it 'returns "--"' do
        expect(@survey.status).to eq('--')
      end
    end

    context 'when there are some active survey assignments' do
      let(:n) { 4 }

      it 'returns a string including the active count' do
        n.times { create(:survey_assignment, survey_id: @survey.id) }
        expect(@survey.status).to match(n.to_s)
      end
    end
  end
end
