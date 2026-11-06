# frozen_string_literal: true

require 'rails_helper'

describe AssignmentSuggestionsController, type: :request do
  describe '#create' do
    let(:course) { create(:course) }
    let(:assignment) { create(:assignment, course:) }
    let(:user) { create(:user) }
    let(:other_user) { create(:user, username: 'SomeoneElse') }
    let(:route) { "/assignments/#{assignment.id}/assignment_suggestions" }

    def suggest(as_user_id: user.id)
      post route, params: { assignment_id: assignment.id,
                            format: :json,
                            feedback: {
                              assignment_id: assignment.id, text: 'foo', user_id: as_user_id
                            } }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'when the user is in the course' do
      before { create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE) }

      it 'creates a record' do
        expect(AssignmentSuggestion.count).to eq(0)
        suggest
        expect(AssignmentSuggestion.count).to eq(1)
      end

      it 'records the signed-in user as the author, whatever user_id is sent' do
        suggest(as_user_id: other_user.id)
        expect(AssignmentSuggestion.last.user).to eq(user)
      end
    end

    context 'when the user is not in the course' do
      it 'refuses the suggestion' do
        suggest
        expect(response.status).to eq(401)
        expect(AssignmentSuggestion.count).to eq(0)
      end
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
