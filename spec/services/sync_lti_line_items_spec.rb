# frozen_string_literal: true

require 'rails_helper'

describe SyncLtiLineItems do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:course) { create(:course) }
  let(:binding) do
    LtiCourseBinding.create!(
      course: course,
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key'
    )
  end

  let(:training_module) do
    create(:training_module, slug: 'get-started', name: 'Get started', kind: 0)
  end
  let(:exercise_module) do
    create(:training_module, slug: 'bibliography', name: 'Bibliography', kind: 1)
  end

  let!(:week) { create(:week, course: course, order: 1) }

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
    # Block.after_commit hook would queue LtiLineItemSyncWorker; stub so the
    # synchronous Sidekiq runner doesn't double-fire during setup.
    allow(LtiLineItemSyncWorker).to receive(:perform_in)
    allow(LtiLineItemSyncWorker).to receive(:perform_async)
    # Discovery lists AGS line items; default to none imported yet.
    stub_line_item_list([])
  end

  def stub_line_item_list(items)
    stub_request(:get, %r{https://#{domain}/api/lineitems})
      .to_return(status: 200, body: { lineItems: items }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  describe 'discovering instructor-imported columns' do
    let!(:training_block) do
      create(:block, week: week, order: 0, title: 'Get started on Wikipedia',
                     training_module_ids: [training_module.id])
    end
    let!(:exercise_block) do
      create(:block, week: week, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'creates nothing in Canvas — the instructor imports every column' do
      expect { described_class.new(binding) }.not_to change(LtiLineItem, :count)
      expect(WebMock).not_to have_requested(:post, %r{/api/lineitems})
    end

    it 'discovers imported columns of every type by tag and binds local rows' do
      stub_line_item_list(
        [{ 'id' => 'https://lms.example.com/li/setup', 'tag' => LtiLineItem::SETUP_TYPE },
         { 'id' => 'https://lms.example.com/li/tr',
           'tag' => LtiLineItem::TRAINING_PROGRESS_TYPE },
         { 'id' => 'https://lms.example.com/li/ex', 'tag' => "Block:#{exercise_block.id}" }]
      )

      expect { described_class.new(binding) }.to change(LtiLineItem, :count).by(3)
      expect(LtiLineItem.pluck(:gradable_type, :gradable_id))
        .to contain_exactly([LtiLineItem::SETUP_TYPE, nil],
                            [LtiLineItem::TRAINING_PROGRESS_TYPE, nil],
                            ['Block', exercise_block.id])
      row = LtiLineItem.find_by(gradable_type: 'Block', gradable_id: exercise_block.id)
      expect(row.lineitem_id).to eq('https://lms.example.com/li/ex')
      expect(row).not_to be_archived
    end

    it 'ignores a Canvas column whose tag matches nothing in the course' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/x',
                             'tag' => 'Block:999999' }])
      expect { described_class.new(binding) }.not_to change(LtiLineItem, :count)
    end

    it 'is idempotent across repeated syncs' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      expect { described_class.new(binding) }.not_to change(LtiLineItem, :count)
    end

    it 'archives a bound exercise row once its Canvas column is gone' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      expect(LtiLineItem.active.count).to eq(1)

      exercise_block.destroy
      stub_line_item_list([]) # column no longer discoverable
      described_class.new(binding)

      row = LtiLineItem.find_by(gradable_type: 'Block', gradable_id: exercise_block.id)
      expect(row).to be_archived
      expect(WebMock).not_to have_requested(:delete, %r{/api/lineitems/})
    end

    it 'revives an archived row when its column comes back' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      LtiLineItem.find_by(gradable_id: exercise_block.id).archive!

      described_class.new(binding)
      expect(LtiLineItem.find_by(gradable_id: exercise_block.id)).not_to be_archived
    end

    # An instructor who deletes an imported assignment and re-imports it gets a
    # new Canvas line item on the same local row. The stored signatures described
    # the old column, so grade sync used to see them as unchanged, skip the push,
    # and leave the new column permanently blank.
    it 'discards stale score signatures when a re-import repoints the row' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      row = LtiLineItem.find_by(gradable_id: exercise_block.id)
      context = LtiContext.create!(lti_course_binding: binding, user: create(:user),
                                   user_lti_id: 'lti-1', lms_id: 'platform-x')
      LtiScoreSignature.create!(lti_line_item: row, lti_context: context,
                                signature: 'pushed-to-the-old-column',
                                last_pushed_at: 1.hour.ago)

      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex-reimported',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)

      expect(row.reload.lineitem_id).to eq('https://lms.example.com/li/ex-reimported')
      expect(LtiScoreSignature.where(lti_line_item_id: row.id)).to be_empty
    end

    # Canvas owns the assignment's name once it exists; we never rename it.
    it 'never pushes a label change to Canvas' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      exercise_block.update!(title: 'Renamed in the Dashboard')
      described_class.new(binding)
      expect(WebMock).not_to have_requested(:put, %r{/api/lineitems/})
    end
  end

  describe 'pending reservations from the deep-link picker' do
    let!(:exercise_block) do
      create(:block, week: week, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end
    let!(:pending_row) do
      LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                          gradable_id: exercise_block.id, label: 'Wk1 Find sources')
    end

    it 'adopts a pending row when discovery finds its column, instead of duplicating' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      expect { described_class.new(binding) }.not_to change(LtiLineItem, :count)
      expect(pending_row.reload.lineitem_id).to eq('https://lms.example.com/li/ex')
      expect(pending_row).not_to be_archived
    end

    # The reservation must keep holding its slot while the 2-minute discovery
    # window (or a slow Canvas) plays out — archiving it would put the
    # gradable back on the picker's menu mid-race.
    it 'leaves a fresh pending row alone when its column has not appeared yet' do
      described_class.new(binding)
      expect(pending_row.reload).to be_pending
      expect(pending_row).not_to be_archived
    end

    it 'destroys a pending row still unbound after the expiry window' do
      pending_row.update_column(:updated_at, (described_class::PENDING_EXPIRY + 1.minute).ago)
      described_class.new(binding)
      expect(LtiLineItem.find_by(id: pending_row.id)).to be_nil
    end

    it 'adopts rather than expires a stale pending row whose column finally shows up' do
      pending_row.update_column(:updated_at, (described_class::PENDING_EXPIRY + 1.minute).ago)
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      expect(pending_row.reload.lineitem_id).to eq('https://lms.example.com/li/ex')
    end

    # A reservation that revived an archived row rolls back to that archived
    # state rather than being destroyed — the row and its Canvas mapping predate
    # the reservation (see LtiLineItem#expire_reservation!).
    it 'rolls back an expired revived reservation instead of destroying it' do
      pending_row.update_columns(
        updated_at: (described_class::PENDING_EXPIRY + 1.minute).ago,
        reserved_prior_state: { 'archived_at' => 2.days.ago,
                                'lineitem_id' => 'https://lms.example.com/li/gone',
                                'canvas_assignment_id' => 'ca-gone',
                                'label' => 'Wk1 Find sources' }.to_json
      )

      described_class.new(binding)

      pending_row.reload
      expect(pending_row).to be_archived
      expect(pending_row.lineitem_id).to eq('https://lms.example.com/li/gone')
    end

    it 'clears the rollback snapshot when discovery adopts the reservation' do
      pending_row.update_column(:reserved_prior_state,
                                { 'lineitem_id' => 'https://lms.example.com/li/gone' }.to_json)
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])

      described_class.new(binding)
      expect(pending_row.reload.reserved_prior_state).to be_nil
    end
  end

  describe 'the local label of a discovered column' do
    # Reuse the seeded module if the CI test DB already has it, rather than
    # creating a duplicate 'bibliography-exercise' slug.
    let(:mapped_exercise) do
      TrainingModule.find_by(slug: 'bibliography-exercise') ||
        create(:training_module, slug: 'bibliography-exercise',
                                 name: 'Building your bibliography', kind: 1)
    end
    let!(:mapped_block) do
      create(:block, week: week, order: 0, title: 'A long timeline block title',
                     training_module_ids: [mapped_exercise.id])
    end

    it 'uses the operator short name, not the block title' do
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/bib',
                             'tag' => "Block:#{mapped_block.id}" }])
      described_class.new(binding)
      row = LtiLineItem.find_by(gradable_type: 'Block', gradable_id: mapped_block.id)
      expect(row.label).to eq('Wk1 Bibliography')
    end
  end

  describe 'no-op cases' do
    it 'is a no-op when binding has no course' do
      binding.update!(course: nil)
      described_class.new(binding)
      expect(LtiLineItem.count).to eq(0)
      expect(WebMock).not_to have_requested(:any, /ltiaas/)
    end

    it 'is a no-op when binding has no service credentials' do
      binding.update!(ltiaas_service_credentials: nil)
      described_class.new(binding)
      expect(LtiLineItem.count).to eq(0)
      expect(WebMock).not_to have_requested(:any, /ltiaas/)
    end
  end
end
