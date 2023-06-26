# frozen_string_literal: true

require 'rails_helper'

describe CheckAssignmentStatus do
  let(:user) { create(:user, username: 'Ragesock') }
  let(:subject) { described_class.new(assignment) }
  let(:role) { Assignment::Roles::ASSIGNED_ROLE }
  let(:assignment) { create(:assignment, role:, sandbox_url:, user:) }

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

  context 'when the bibliography sandbox exists' do
    let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox_empty' }

    it 'updates the bibliography draft sandbox status' do
      expect(assignment.bibliography_sandbox_status).to eq('does_not_exist')
      VCR.use_cassette 'assignment_status' do
        subject
      end
      assignment.reload
      expect(assignment.draft_sandbox_status).to eq('does_not_exist')
      expect(assignment.bibliography_sandbox_status).to eq('exists_in_userspace')
    end

    context 'whent the sandbox include URL-encoded characters' do
      let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Sage (Wiki Ed)/Fender_%28company%29' }

      it 'still works' do
        expect(assignment.bibliography_sandbox_status).to eq('does_not_exist')
        VCR.use_cassette 'assignment_status' do
          subject
        end
        assignment.reload
        expect(assignment.draft_sandbox_status).to eq('exists_in_userspace')
        expect(assignment.bibliography_sandbox_status).to eq('exists_in_userspace')
      end
    end
  end

  context 'when a peer review sandbox exists' do
    let(:role) { Assignment::Roles::REVIEWING_ROLE }
    let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox' }
    # Peer review sandbox: https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox/Ragesock_Peer_Review

    it 'updates the peer review sandbox sandbox status' do
      expect(assignment.peer_review_sandbox_status).to eq('does_not_exist')
      VCR.use_cassette 'assignment_status' do
        subject
      end
      assignment.reload
      expect(assignment.peer_review_sandbox_status).to eq('exists_in_userspace')
    end
  end

  context 'when an assignment pipeline status is set' do
    let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox' }

    it 'does not overwrite it when updating sandbox status' do
      assignment.update_status('assignment_completed')
      expect(assignment.draft_sandbox_status).to eq('does_not_exist')
      VCR.use_cassette 'assignment_status' do
        subject
      end
      assignment.reload
      expect(assignment.draft_sandbox_status).to eq('exists_in_userspace')
      expect(assignment.status).to eq('assignment_completed')
    end
  end

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
        described_class.check_current_assignments
      end

      expect(assignment_1.reload.draft_sandbox_status).to eq('exists_in_userspace')
      expect(assignment_2.reload.peer_review_sandbox_status).to eq('exists_in_userspace')
    end
  end
end
