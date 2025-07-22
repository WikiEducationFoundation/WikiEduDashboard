# frozen_string_literal: true

require 'rails_helper'

describe AssignmentSuggestionsController, type: :request do
  describe '#create' do
    let(:assignment) { create(:assignment) }
    let(:user) { create(:user) }
    let(:route) { "/assignments/#{assignment.id}/assignment_suggestions" }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    it 'creates a record' do
      expect(AssignmentSuggestion.count).to eq(0)
      post route, params: { assignment_id: assignment.id,
                            format: :json,
                            feedback: {
                              assignment_id: assignment.id, text: 'foo', user_id: user.id
                            } }
      expect(AssignmentSuggestion.count).to eq(1)
    end
  end

  describe '#destroy' do
    let(:assignment) { create(:assignment) }
    let(:assignment_suggestion) do
      create(:assignment_suggestion, user: owner, assignment:)
    end
    let(:owner) { create(:user) }
    let(:nonowner) { create(:user, username: 'AnotherUser') }
    let(:admin) { create(:admin) }
    let(:route) do
      "/assignments/#{assignment.id}/assignment_suggestions/#{assignment_suggestion.id}"
    end

    let(:subject) do
      delete route, params: { assignment_id: assignment.id, id: assignment_suggestion.id }
    end

    context 'when the user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'destroys the suggestion' do
        subject
        expect(response.status).to eq(200)
        expect(AssignmentSuggestion.exists?(assignment_suggestion.id)).to eq(false)
      end
    end

    context 'when the user owns the suggestion' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(owner)
      end

      it 'destroys the suggestion' do
        subject
        expect(response.status).to eq(200)
        expect(AssignmentSuggestion.exists?(assignment_suggestion.id)).to eq(false)
      end
    end

    context 'when a non-admin user does not own the suggestion' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nonowner)
      end

      it 'return a 401 not authorized' do
        subject
        expect(response.status).to eq(401)
        expect(AssignmentSuggestion.exists?(assignment_suggestion.id)).to eq(true)
      end
    end
  end
end
