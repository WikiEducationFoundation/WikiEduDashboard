# frozen_string_literal: true

require 'rails_helper'

describe CheckAssignmentStatus do
  let(:user) { create(:user, username: 'Ragesock') }
  let(:subject) { described_class.check_current_assignments }
  let(:role) { Assignment::Roles::ASSIGNED_ROLE }
  let(:assignment) { create(:assignment, role:, sandbox_url:, user:) }

  describe '.check_current_assignments' do
    let(:course) { create(:course, start: 1.day.ago, end: 1.day.from_now) }
    # also exists: https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox/Ragesock_Peer_Review
    let(:existing_sandbox_1) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox' }
    let(:assignment_1) do
      create(:assignment, course:, user:, role:, sandbox_url: existing_sandbox_1)
    end
    let(:assignment_2) do
      create(:assignment, course:, user:, role: Assignment::Roles::REVIEWING_ROLE,
                          sandbox_url: existing_sandbox_1)
    end

    it 'updates status for all current course assignments' do
      expect(assignment_1.draft_sandbox_status).to eq('does_not_exist')
      expect(assignment_2.peer_review_sandbox_status).to eq('does_not_exist')

      VCR.use_cassette 'assignment_status' do
        subject
      end

      expect(assignment_1.reload.draft_sandbox_status).to eq('exists_in_userspace')
      expect(assignment_2.reload.peer_review_sandbox_status).to eq('exists_in_userspace')
    end

    context 'when the draft sandbox exists' do
      let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox' }
  
      it 'updates the Assignment draft sandbox status' do
        expect(assignment.draft_sandbox_status).to eq('does_not_exist')
        VCR.use_cassette 'assignment_status' do
          subject
        end
        assignment.reload
        expect(assignment.draft_sandbox_status).to eq('exists_in_userspace')
        expect(assignment.bibliography_sandbox_status).to eq('does_not_exist')
      end
    end
  end
end
