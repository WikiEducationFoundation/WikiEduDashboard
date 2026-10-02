# frozen_string_literal: true

require 'rails_helper'

describe ReserveLtiLineItems do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end

  def gradable(type: 'Block', id: 1, label: 'Wk1 Find sources')
    DeepLinkableGradables::Gradable.new(resource: "#{type}:#{id}", gradable_type: type,
                                        gradable_id: id, label:)
  end

  it 'reserves a free gradable with a pending row carrying its label' do
    reservation = nil
    expect { reservation = described_class.new(binding:, gradables: [gradable]) }
      .to change(LtiLineItem.pending, :count).by(1)
    expect(reservation.reserved).to be(true)
    row = LtiLineItem.last
    expect(row.lineitem_id).to be_nil
    expect(row.label).to eq('Wk1 Find sources')
    expect(row).not_to be_archived
  end

  # The double-submit race: the other request's reservation is already
  # committed by the time this one tries.
  it 'refuses a gradable another request has already reserved' do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block', gradable_id: 1)
    reservation = described_class.new(binding:, gradables: [gradable])
    expect(reservation.reserved).to be(false)
  end

  it 'refuses a gradable already backed by a bound column' do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block', gradable_id: 1,
                        lineitem_id: 'https://canvas/li/existing')
    expect(described_class.new(binding:, gradables: [gradable]).reserved).to be(false)
  end

  # One losing slot must not leave the other slots reserved, or a retried
  # submission would 422 against our own leftovers.
  it 'rolls back every slot when any one of them is taken' do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block', gradable_id: 2,
                        lineitem_id: 'https://canvas/li/existing')
    reservation = described_class.new(binding:,
                                      gradables: [gradable(id: 1), gradable(id: 2)])
    expect(reservation.reserved).to be(false)
    expect(LtiLineItem.pending).to be_empty
  end

  # A column deleted in Canvas leaves an archived row occupying the
  # (binding, gradable_key) unique slot; re-importing the gradable re-uses
  # that row rather than colliding with it.
  describe 'when the slot holds an archived row' do
    let!(:archived_row) do
      LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block', gradable_id: 1,
                          lineitem_id: 'https://canvas/li/old',
                          canvas_assignment_id: 'ca-old',
                          archived_at: 1.day.ago)
    end

    it 'revives it as the pending reservation' do
      reservation = nil
      expect { reservation = described_class.new(binding:, gradables: [gradable]) }
        .not_to change(LtiLineItem, :count)
      expect(reservation.reserved).to be(true)
      expect(archived_row.reload).to be_pending
      expect(archived_row).not_to be_archived
    end

    # The old column is gone; a stale canvas_assignment_id would route a new
    # assignment's launch to the wrong row.
    it 'clears the dead column identifiers' do
      described_class.new(binding:, gradables: [gradable])
      archived_row.reload
      expect(archived_row.lineitem_id).to be_nil
      expect(archived_row.canvas_assignment_id).to be_nil
    end

    # The compare-and-swap: a competitor who revived (row now active) between
    # our offerable check and the reservation reads as a lost race.
    it 'refuses when a concurrent request revived the row first' do
      archived_row.update!(archived_at: nil, lineitem_id: nil)
      expect(described_class.new(binding:, gradables: [gradable]).reserved).to be(false)
    end

    # #release only covers failures inside this request. When the form response
    # succeeds and Canvas never creates the assignment, the rollback happens in a
    # sync process minutes later that has nothing but the row — so the snapshot
    # has to be on the row itself (see LtiLineItem#expire_reservation!).
    it 'persists the overwritten attributes on the row' do
      described_class.new(binding:, gradables: [gradable])

      prior = archived_row.reload.reserved_prior_attributes
      expect(prior['lineitem_id']).to eq('https://canvas/li/old')
      expect(prior['canvas_assignment_id']).to eq('ca-old')
      expect(prior['archived_at']).to be_present
    end

    it 'leaves no snapshot on a reservation that created its own row' do
      described_class.new(binding:, gradables: [gradable(id: 2)])
      expect(LtiLineItem.find_by(gradable_id: 2).reserved_prior_state).to be_nil
    end
  end

  describe '#release' do
    it 'deletes a fresh reservation' do
      reservation = described_class.new(binding:, gradables: [gradable])
      expect { reservation.release }.to change(LtiLineItem, :count).by(-1)
    end

    # Adoption can land between the failure and the release (a concurrent
    # discovery run); release must not delete a live, bound mapping.
    it 'keeps a reservation that was adopted before the release' do
      reservation = described_class.new(binding:, gradables: [gradable])
      row = LtiLineItem.last
      LtiLineItem.where(id: row.id).update_all(lineitem_id: 'https://canvas/li/live')
      reservation.release
      expect(row.reload.lineitem_id).to eq('https://canvas/li/live')
    end

    describe 'when the reservation revived an archived row' do
      let!(:archived_row) do
        LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                            gradable_id: 1, lineitem_id: 'https://canvas/li/old',
                            canvas_assignment_id: 'ca-old', label: 'Old label',
                            archived_at: 1.day.ago)
      end
      let!(:signature) do
        context = LtiContext.create!(lti_course_binding: binding, user: create(:user),
                                     user_lti_id: 'lti-1', lms_id: 'platform-x')
        LtiScoreSignature.create!(lti_line_item: archived_row, lti_context: context,
                                  signature: 'abc', last_pushed_at: 1.day.ago)
      end

      # A hard delete here would erase the historical mapping and its
      # signatures; release is a rollback, not a teardown.
      it 'restores the prior archived state instead of deleting the row' do
        reservation = described_class.new(binding:, gradables: [gradable])
        reservation.release
        archived_row.reload
        expect(archived_row).to be_archived
        expect(archived_row.lineitem_id).to eq('https://canvas/li/old')
        expect(archived_row.canvas_assignment_id).to eq('ca-old')
        expect(archived_row.label).to eq('Old label')
        expect(LtiScoreSignature.exists?(signature.id)).to be(true)
      end

      it 'keeps the row when it was adopted before the release' do
        reservation = described_class.new(binding:, gradables: [gradable])
        LtiLineItem.where(id: archived_row.id)
                   .update_all(lineitem_id: 'https://canvas/li/new')
        reservation.release
        expect(archived_row.reload.lineitem_id).to eq('https://canvas/li/new')
        expect(archived_row).not_to be_archived
      end
    end
  end
end
