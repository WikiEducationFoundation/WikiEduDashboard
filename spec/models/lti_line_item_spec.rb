# frozen_string_literal: true

require 'rails_helper'

describe LtiLineItem do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99'
    )
  end

  describe 'validations' do
    it 'is valid as a TrainingProgress sentinel with no gradable_id' do
      li = described_class.new(
        lti_course_binding: binding,
        gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
        lineitem_id: 'http://lms/li/1'
      )
      expect(li).to be_valid
    end

    it 'requires gradable_type and lineitem_id' do
      li = described_class.new(lti_course_binding: binding)
      expect(li).not_to be_valid
      expect(li.errors[:gradable_type]).to be_present
      expect(li.errors[:lineitem_id]).to be_present
    end

    it 'rejects duplicate (binding, gradable_type, gradable_id)' do
      described_class.create!(lti_course_binding: binding,
                              gradable_type: 'Block', gradable_id: 1,
                              lineitem_id: 'http://lms/li/1')
      dup = described_class.new(lti_course_binding: binding,
                                gradable_type: 'Block', gradable_id: 1,
                                lineitem_id: 'http://lms/li/2')
      expect(dup).not_to be_valid
    end
  end

  describe 'archiving' do
    let!(:active_li) do
      described_class.create!(
        lti_course_binding: binding,
        gradable_type: 'Block', gradable_id: 1,
        lineitem_id: 'http://lms/li/1'
      )
    end

    it 'partitions via active / archived scopes' do
      expect(described_class.active).to include(active_li)
      expect(described_class.archived).to be_empty

      active_li.archive!
      expect(described_class.active).to be_empty
      expect(described_class.archived).to include(active_li)
    end

    it '#archive! is idempotent' do
      active_li.archive!
      first_archived_at = active_li.reload.archived_at
      active_li.archive!
      expect(active_li.reload.archived_at).to eq(first_archived_at)
    end
  end
end
