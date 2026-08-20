# frozen_string_literal: true

require 'rails_helper'

describe ResolveAssignmentLineItem do
  let(:course) { create(:course) }
  let(:binding) do
    LtiCourseBinding.create!(course: course, lms_id: 'p', lms_family: 'canvas',
                             lms_context_id: 'c-1', lms_resource_link_id: 'rl-1')
  end
  let!(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                        gradable_id: 1, lineitem_id: 'https://canvas/li/7', label: 'Evaluate')
  end

  def session(canvas_assignment_id:, ags_lineitem_url:, deep_link_resource: nil)
    instance_double(LtiSession, canvas_assignment_id:, ags_lineitem_url:, deep_link_resource:)
  end

  it 'finds by canvas_assignment_id when it has already been captured' do
    line_item.update!(canvas_assignment_id: 'ca-1')
    lti_session = session(canvas_assignment_id: 'ca-1', ags_lineitem_url: nil)
    expect(described_class.new(binding:, lti_session:).result).to eq(line_item)
  end

  it 'falls back to the launch line-item URL and backfills canvas_assignment_id' do
    lti_session = session(canvas_assignment_id: 'ca-2', ags_lineitem_url: 'https://canvas/li/7')
    expect(described_class.new(binding:, lti_session:).result).to eq(line_item)
    expect(line_item.reload.canvas_assignment_id).to eq('ca-2')
  end

  it 'returns nil when neither the id nor the URL matches' do
    lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/NOPE')
    expect(described_class.new(binding:, lti_session:).result).to be_nil
  end

  it 'ignores archived line items' do
    line_item.archive!
    lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/7')
    expect(described_class.new(binding:, lti_session:).result).to be_nil
  end

  describe 'first launch of a deep-link-created assignment (no local row yet)' do
    let!(:week) { create(:week, course:, order: 1) }
    let(:exercise_module) do
      create(:training_module, slug: 'biblio', name: 'Bibliography', kind: 1)
    end
    let!(:exercise_block) do
      create(:block, week:, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    before do
      allow(LtiLineItemSyncWorker).to receive(:perform_in)
      allow(LtiLineItemSyncWorker).to receive(:perform_async)
    end

    it 'binds a new line item from the resource marker and returns it' do
      lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/NEW',
                            deep_link_resource: "Block:#{exercise_block.id}")
      result = nil
      expect { result = described_class.new(binding:, lti_session:).result }
        .to change(LtiLineItem, :count).by(1)
      expect(result.gradable_type).to eq('Block')
      expect(result.gradable_id).to eq(exercise_block.id)
      expect(result.lineitem_id).to eq('https://canvas/li/NEW')
      expect(result.label).to eq('Wk1 Find sources')
    end

    it 'does not bind a resource that is not one of the course gradables' do
      lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/NEW',
                            deep_link_resource: 'Block:999999')
      expect { described_class.new(binding:, lti_session:) }.not_to change(LtiLineItem, :count)
    end

    it 'is idempotent across repeated launches of the same assignment' do
      sess = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/NEW',
                     deep_link_resource: "Block:#{exercise_block.id}")
      described_class.new(binding:, lti_session: sess)
      expect { described_class.new(binding:, lti_session: sess) }
        .not_to change(LtiLineItem, :count)
    end

    # The deep-link picker reserves the gradable with a pending row before
    # Canvas creates the column, so the first launch usually arrives while
    # that reservation still holds the slot. It must be adopted — filled in
    # from the launch — not collided with, and never returned column-less.
    context 'when the picker reservation (pending row) still holds the gradable' do
      let!(:pending_row) do
        LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                            gradable_id: exercise_block.id, label: 'Wk1 Find sources')
      end

      it 'adopts the pending row via the resource marker instead of colliding' do
        lti_session = session(canvas_assignment_id: 'ca-9',
                              ags_lineitem_url: 'https://canvas/li/NEW',
                              deep_link_resource: "Block:#{exercise_block.id}")
        result = nil
        expect { result = described_class.new(binding:, lti_session:).result }
          .not_to change(LtiLineItem, :count)
        expect(result.id).to eq(pending_row.id)
        expect(pending_row.reload.lineitem_id).to eq('https://canvas/li/NEW')
        expect(pending_row.canvas_assignment_id).to eq('ca-9')
      end

      it 'adopts the pending row via the tagged launch line item when no marker is echoed' do
        service = instance_double(
          LtiServiceSession,
          list_line_items: [{ 'id' => 'https://canvas/li/NEW',
                              'tag' => "Block:#{exercise_block.id}" }]
        )
        allow(LtiServiceSession).to receive(:new).and_return(service)
        lti_session = session(canvas_assignment_id: nil,
                              ags_lineitem_url: 'https://canvas/li/NEW')
        result = nil
        expect { result = described_class.new(binding:, lti_session:).result }
          .not_to change(LtiLineItem, :count)
        expect(result.id).to eq(pending_row.id)
        expect(pending_row.reload.lineitem_id).to eq('https://canvas/li/NEW')
      end
    end
  end
end
