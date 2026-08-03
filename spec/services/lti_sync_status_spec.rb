# frozen_string_literal: true

require 'rails_helper'

describe LtiSyncStatus do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end

  # Both status surfaces read these two counts from here, and they are different
  # numbers: reporting the connected-account count alone, under a label that read
  # as the roster, showed "0 students" for a course whose roster sync had just
  # discovered everybody.
  describe 'the roster and connected-account counts' do
    let(:learner_roles) { ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'] }

    def learner(user_lti_id, user: nil, status: 'Active')
      LtiContext.create!(lti_course_binding: binding, user:, user_lti_id:,
                         lms_id: 'platform-x', roles: learner_roles,
                         lms_membership_status: status,
                         linked_at: user && 1.day.ago)
    end

    it 'counts every roster learner but only the connected ones as accounts' do
      learner('l1', user: create(:user, username: 'Connected'))
      learner('l2')

      status = described_class.new(binding)
      expect(status.roster_students_count).to eq(2)
      expect(status.connected_accounts_count).to eq(1)
    end

    it 'leaves LMS-removed members out of the roster count' do
      learner('l1')
      learner('l2', status: 'Deleted')
      learner('l3', status: 'Inactive')

      expect(described_class.new(binding).roster_students_count).to eq(1)
    end

    # A Canvas observer or designer is neither, and course staff are not
    # students — same classification the grade pushes use.
    it 'counts neither instructors nor non-learner roles' do
      LtiContext.create!(lti_course_binding: binding, user_lti_id: 't1',
                         lms_id: 'platform-x', user: create(:user, username: 'Teacher'),
                         roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'])
      LtiContext.create!(lti_course_binding: binding, user_lti_id: 'o1',
                         lms_id: 'platform-x',
                         roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor'])

      status = described_class.new(binding)
      expect(status.roster_students_count).to eq(0)
      expect(status.connected_accounts_count).to eq(0)
    end
  end

  # Gates the instructor status view's how-to-import next step, which must
  # keep showing until a Canvas column really exists.
  describe '#assignments_imported?' do
    it 'is false when nothing has been imported' do
      expect(described_class.new(binding).assignments_imported?).to be(false)
    end

    # A pending row is only the deep-link picker's reservation; if the form
    # never reached Canvas, nothing was imported and the how-to must stay up.
    it 'is false when only a pending reservation exists' do
      LtiLineItem.create!(lti_course_binding: binding,
                          gradable_type: 'Block', gradable_id: 1)
      expect(described_class.new(binding).assignments_imported?).to be(false)
    end

    it 'is true once a line item is bound to a Canvas column' do
      LtiLineItem.create!(lti_course_binding: binding,
                          gradable_type: 'Block', gradable_id: 1,
                          lineitem_id: 'https://canvas/li/1')
      expect(described_class.new(binding).assignments_imported?).to be(true)
    end

    it 'is false when the only bound line item is archived' do
      LtiLineItem.create!(lti_course_binding: binding,
                          gradable_type: 'Block', gradable_id: 1,
                          lineitem_id: 'https://canvas/li/1', archived_at: 1.day.ago)
      expect(described_class.new(binding).assignments_imported?).to be(false)
    end
  end
end
