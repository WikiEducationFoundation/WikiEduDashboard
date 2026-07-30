# frozen_string_literal: true

require 'rails_helper'

describe LtiSyncStatus do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
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
