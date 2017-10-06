# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_suggestions
#
#  id            :integer          not null, primary key
#  text          :text(65535)
#  assignment_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer
#

require 'rails_helper'

RSpec.describe AssignmentSuggestion, type: :model do
  let(:assignment) { create(:assignment) }
  let!(:assignment_suggestion) { create(:assignment_suggestion, assignment: assignment) }
  it 'is destroyed when its Assignment is destroyed' do
    expect(assignment_suggestion).to be
    assignment.destroy
    expect(AssignmentSuggestion.exists?(assignment_suggestion.id)).to eq(false)
  end
end
