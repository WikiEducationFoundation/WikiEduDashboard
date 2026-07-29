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

    # The sentinel types carry gradable_id = NULL, which MySQL exempts from the
    # composite unique index, so the validator is the only thing holding the
    # "one trainings roll-up / one account column per binding" invariant.
    it 'rejects a duplicate sentinel line item for the same binding' do
      described_class.create!(lti_course_binding: binding,
                              gradable_type: LtiLineItem::SETUP_TYPE,
                              lineitem_id: 'http://lms/li/1')
      dup = described_class.new(lti_course_binding: binding,
                                gradable_type: LtiLineItem::SETUP_TYPE,
                                lineitem_id: 'http://lms/li/2')
      expect(dup).not_to be_valid
      expect(dup.errors[:gradable_id]).to be_present
    end

    # The validation is a convenience; `gradable_key` (a stored generated column
    # folding the sentinels' null gradable_id into a non-null string) is what
    # actually holds the invariant, because MySQL exempts NULLs from unique
    # indexes and two concurrent creates can both pass validation.
    it 'rejects a duplicate sentinel at the database level, bypassing validation' do
      described_class.create!(lti_course_binding: binding,
                              gradable_type: LtiLineItem::SETUP_TYPE,
                              lineitem_id: 'http://lms/li/1')
      expect do
        described_class.insert_all!([{ lti_course_binding_id: binding.id,
                                       gradable_type: LtiLineItem::SETUP_TYPE,
                                       lineitem_id: 'http://lms/li/2',
                                       score_maximum: 1.0,
                                       created_at: Time.current, updated_at: Time.current }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'rejects a duplicate Block line item at the database level too' do
      described_class.create!(lti_course_binding: binding, gradable_type: 'Block',
                              gradable_id: 7, lineitem_id: 'http://lms/li/1')
      expect do
        described_class.insert_all!([{ lti_course_binding_id: binding.id,
                                       gradable_type: 'Block', gradable_id: 7,
                                       lineitem_id: 'http://lms/li/2',
                                       score_maximum: 1.0,
                                       created_at: Time.current, updated_at: Time.current }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'still allows the same sentinel type on a different binding' do
      other = LtiCourseBinding.create!(lms_id: 'platform-x', lms_family: 'canvas',
                                       lms_context_id: 'canvas-course-88',
                                       lms_resource_link_id: 'rl-1')
      described_class.create!(lti_course_binding: binding,
                              gradable_type: LtiLineItem::SETUP_TYPE,
                              lineitem_id: 'http://lms/li/1')
      expect(described_class.new(lti_course_binding: other,
                                 gradable_type: LtiLineItem::SETUP_TYPE,
                                 lineitem_id: 'http://lms/li/2')).to be_valid
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
