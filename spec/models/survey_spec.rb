# frozen_string_literal: true

# == Schema Information
#
# Table name: surveys
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  intro                :text(65535)
#  thanks               :text(65535)
#  open                 :boolean          default(FALSE)
#  closed               :boolean          default(FALSE)
#  confidential_results :boolean          default(FALSE)
#  optout               :text(65535)
#

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
