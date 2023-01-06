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
end
