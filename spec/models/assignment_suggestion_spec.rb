# frozen_string_literal: true
# == Schema Information
#
# Table name: assignment_suggestions
#
#  id            :bigint(8)        not null, primary key
#  text          :text(65535)
#  assignment_id :bigint(8)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer
#

require 'rails_helper'

RSpec.describe AssignmentSuggestion, type: :model do
  let(:assignment) { create(:assignment) }
  let!(:assignment_suggestion) { create(:assignment_suggestion, assignment:) }

  it 'is destroyed when its Assignment is destroyed' do
    expect(assignment_suggestion).not_to be_nil
    assignment.destroy
    expect(described_class.exists?(assignment_suggestion.id)).to eq(false)
  end
end
