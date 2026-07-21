# frozen_string_literal: true

require 'rails_helper'

describe LtiCourseBinding do
  let(:base_attrs) do
    {
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99'
    }
  end

  describe 'validations' do
    it 'requires the LMS identity tuple' do
      binding = described_class.new
      expect(binding).not_to be_valid
      expect(binding.errors[:lms_id]).to be_present
      expect(binding.errors[:lms_context_id]).to be_present
      expect(binding.errors[:lms_resource_link_id]).to be_present
    end

    it 'rejects unknown gradebook_granularity' do
      binding = described_class.new(base_attrs.merge(gradebook_granularity: 'weird'))
      expect(binding).not_to be_valid
      expect(binding.errors[:gradebook_granularity]).to be_present
    end

    it "defaults gradebook_granularity to 'lumped'" do
      binding = described_class.create!(base_attrs)
      expect(binding.gradebook_granularity).to eq('lumped')
      expect(binding).to be_lumped
      expect(binding).not_to be_per_block
    end

    it 'allows only one binding per linked course' do
      course = create(:course)
      described_class.create!(base_attrs.merge(course:))
      dup = described_class.new(base_attrs.merge(course:, lms_resource_link_id: 'rl-2'))
      expect(dup).not_to be_valid
      expect(dup.errors[:course_id]).to be_present
    end

    it 'allows many bindings that have no course yet' do
      described_class.create!(base_attrs)
      expect(described_class.new(base_attrs.merge(lms_resource_link_id: 'rl-2'))).to be_valid
    end
  end

  describe '.lookup' do
    it 'finds an existing binding by LMS identity tuple' do
      binding = described_class.create!(base_attrs)
      expect(described_class.lookup(**base_attrs.slice(:lms_id, :lms_context_id,
                                                       :lms_resource_link_id)))
        .to eq(binding)
    end
  end

  describe '#lms_display_name' do
    it 'returns the configured label for known LMS families' do
      binding = described_class.new(base_attrs.merge(lms_family: 'canvas'))
      expect(binding.lms_display_name).to eq('Canvas')
    end

    it 'titleizes the family code as a fallback for unknown LMSs' do
      binding = described_class.new(base_attrs.merge(lms_family: 'moodle'))
      expect(binding.lms_display_name).to eq('Moodle')
    end
  end

  describe 'optional course association' do
    it 'permits a nil course while waiting on instructor setup' do
      binding = described_class.create!(base_attrs)
      expect(binding.course).to be_nil
    end

    it 'destroys associated lti_contexts and lti_line_items on destroy' do
      binding = described_class.create!(base_attrs)
      LtiContext.create!(user_lti_id: 'u',
                         lms_id: 'platform-x',
                         lti_course_binding: binding)
      LtiLineItem.create!(lti_course_binding: binding,
                          gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                          lineitem_id: 'http://lms/li/1')

      expect { binding.destroy }
        .to change(LtiContext, :count).by(-1)
        .and change(LtiLineItem, :count).by(-1)
    end
  end
end
