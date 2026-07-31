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

  # Deleting an imported Canvas assignment and re-importing it repoints this row
  # at a new Canvas line item. Signatures are keyed on the row, so without this
  # they described a column that no longer exists — grade sync saw an unchanged
  # signature, skipped the push, and left the new column blank.
  describe 'score signatures when the Canvas line item is repointed' do
    let(:line_item) do
      described_class.create!(lti_course_binding: binding, gradable_type: 'Block',
                              gradable_id: 5, lineitem_id: 'https://canvas/li/old')
    end
    let(:context) do
      LtiContext.create!(lti_course_binding: binding, user: create(:user),
                         user_lti_id: 'lti-1', lms_id: 'platform-x')
    end

    before do
      LtiScoreSignature.create!(lti_line_item: line_item, lti_context: context,
                                signature: 'abc', last_pushed_at: 1.hour.ago)
    end

    it 'discards them when lineitem_id changes' do
      expect { line_item.update!(lineitem_id: 'https://canvas/li/new') }
        .to change(LtiScoreSignature, :count).by(-1)
    end

    it 'keeps them when some other attribute changes' do
      expect { line_item.update!(label: 'Renamed') }
        .not_to change(LtiScoreSignature, :count)
    end

    it 'keeps them when the row is re-saved with the same lineitem_id' do
      expect { line_item.update!(lineitem_id: 'https://canvas/li/old', archived_at: nil) }
        .not_to change(LtiScoreSignature, :count)
    end

    # The shape of the update that bind_discovered_line_item performs.
    it 'discards them on the repoint a re-import performs' do
      line_item.update!(lineitem_id: 'https://canvas/li/reimported', archived_at: nil)
      expect(LtiScoreSignature.where(lti_line_item_id: line_item.id)).to be_empty
    end
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

    it 'requires gradable_type' do
      li = described_class.new(lti_course_binding: binding)
      expect(li).not_to be_valid
      expect(li.errors[:gradable_type]).to be_present
    end

    # A nil lineitem_id is a pending reservation from the deep-link picker,
    # created before Canvas has made the column.
    it 'is valid as a pending reservation with no lineitem_id' do
      li = described_class.new(lti_course_binding: binding,
                               gradable_type: 'Block', gradable_id: 1)
      expect(li).to be_valid
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

  describe 'pending reservations' do
    let!(:pending_li) do
      described_class.create!(lti_course_binding: binding,
                              gradable_type: 'Block', gradable_id: 1)
    end
    let!(:bound_li) do
      described_class.create!(lti_course_binding: binding,
                              gradable_type: 'Block', gradable_id: 2,
                              lineitem_id: 'http://lms/li/2')
    end

    it 'partitions via pending / bound scopes' do
      expect(described_class.pending).to contain_exactly(pending_li)
      expect(described_class.bound).to contain_exactly(bound_li)
    end

    it '#pending? reflects the missing lineitem_id' do
      expect(pending_li).to be_pending
      expect(bound_li).not_to be_pending
    end

    # MariaDB exempts NULLs from the (binding, lineitem_id) unique index, so
    # one binding can hold reservations for several gradables at once.
    it 'allows multiple pending rows on one binding despite the unique index' do
      expect do
        described_class.create!(lti_course_binding: binding,
                                gradable_type: 'Block', gradable_id: 3)
      end.to change(described_class.pending, :count).by(1)
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

  # Expiry re-checks under a row lock because the sync's snapshot of the row
  # predates its remote fetch — a launch can adopt the reservation in between,
  # and an unconditional destroy would delete a live, bound column mapping.
  describe '#expire_reservation!' do
    let(:cutoff) { 30.minutes.ago }

    def create_reservation(updated_at: 31.minutes.ago)
      described_class.create!(lti_course_binding: binding, gradable_type: 'Block',
                              gradable_id: 5).tap do |row|
        row.update_column(:updated_at, updated_at)
      end
    end

    it 'destroys a stale pending reservation' do
      row = create_reservation
      row.expire_reservation!(older_than: cutoff)
      expect(described_class.exists?(row.id)).to be(false)
    end

    it 'keeps a reservation younger than the cutoff' do
      row = create_reservation(updated_at: 5.minutes.ago)
      row.expire_reservation!(older_than: cutoff)
      expect(described_class.exists?(row.id)).to be(true)
    end

    it 'keeps a reservation that was adopted after this copy was loaded' do
      row = create_reservation
      stale_copy = described_class.find(row.id)
      described_class.where(id: row.id).update_all(lineitem_id: 'https://canvas/li/live')
      stale_copy.expire_reservation!(older_than: cutoff)
      expect(row.reload.lineitem_id).to eq('https://canvas/li/live')
    end

    it 'tolerates a reservation another sync already expired' do
      row = create_reservation
      described_class.where(id: row.id).delete_all
      expect { row.expire_reservation!(older_than: cutoff) }.not_to raise_error
    end
  end
end
