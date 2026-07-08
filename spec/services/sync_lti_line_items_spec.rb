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
      ltiaas_service_credentials: 'svc-key',
      gradebook_granularity:
    )
  end
  let(:gradebook_granularity) { 'lumped' }

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
    # The always-present setup ("connected") column, matched by tag since its
    # label is operator-supplied.
    stub_request(:post, "https://#{domain}/api/lineitems")
      .with(body: hash_including(tag: LtiLineItem::SETUP_TYPE))
      .to_return(status: 201,
                 body: { id: 'https://lms.example.com/li/setup', scoreMaximum: 1.0 }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    # Deep-link exercise-column discovery lists AGS line items; default to none.
    stub_line_item_list([])
  end

  def stub_post_lineitem(label:, lineitem_id: nil)
    lineitem_id ||= "https://lms.example.com/li/#{SecureRandom.hex(4)}"
    stub_request(:post, "https://#{domain}/api/lineitems")
      .with(body: hash_including(label: label))
      .to_return(status: 201,
                 body: { id: lineitem_id, label:, scoreMaximum: 1.0 }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    lineitem_id
  end

  def stub_line_item_list(items)
    stub_request(:get, %r{https://#{domain}/api/lineitems})
      .to_return(status: 200, body: { lineItems: items }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  describe 'lumped granularity' do
    let!(:training_block) do
      create(:block, week: week, order: 0, title: 'Get started on Wikipedia',
                     training_module_ids: [training_module.id])
    end
    let!(:exercise_block) do
      create(:block, week: week, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'creates the setup + trainings sentinels but no exercise columns' do
      stub_post_lineitem(label: 'Wikipedia trainings',
                         lineitem_id: 'https://lms.example.com/li/trainings')

      expect { described_class.new(binding) }.to change(LtiLineItem, :count).by(2)
      expect(LtiLineItem.pluck(:gradable_type))
        .to contain_exactly(LtiLineItem::SETUP_TYPE, LtiLineItem::TRAINING_PROGRESS_TYPE)
    end

    it 'discovers a deep-link exercise column by tag and binds a local row' do
      stub_post_lineitem(label: 'Wikipedia trainings')
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])

      expect { described_class.new(binding) }.to change(LtiLineItem, :count).by(3)
      row = LtiLineItem.find_by(gradable_type: 'Block', gradable_id: exercise_block.id)
      expect(row.lineitem_id).to eq('https://lms.example.com/li/ex')
      expect(row).not_to be_archived
    end

    it 'archives a bound exercise row once its Canvas column is gone' do
      stub_post_lineitem(label: 'Wikipedia trainings')
      stub_line_item_list([{ 'id' => 'https://lms.example.com/li/ex',
                             'tag' => "Block:#{exercise_block.id}" }])
      described_class.new(binding)
      expect(LtiLineItem.active.count).to eq(3) # setup + trainings + discovered exercise

      exercise_block.destroy
      stub_line_item_list([]) # column no longer discoverable
      described_class.new(binding)

      row = LtiLineItem.find_by(gradable_type: 'Block', gradable_id: exercise_block.id)
      expect(row).to be_archived
      expect(WebMock).not_to have_requested(:delete, %r{/api/lineitems/})
    end
  end

  describe 'per_block granularity' do
    let(:gradebook_granularity) { 'per_block' }
    let!(:training_block) do
      create(:block, week: week, order: 0, title: 'Get started',
                     training_module_ids: [training_module.id])
    end
    let!(:exercise_block) do
      create(:block, week: week, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end
    let!(:bare_block) do
      create(:block, week: week, order: 2, title: 'No modules', training_module_ids: [])
    end

    it 'creates one line item per block with training_module_ids, none for bare blocks' do
      stub_post_lineitem(label: 'Wk1 Get started')
      stub_post_lineitem(label: 'Wk1 Find sources')

      expect { described_class.new(binding) }
        .to change(LtiLineItem, :count).by(3)
      expect(LtiLineItem.pluck(:gradable_type, :gradable_id))
        .to contain_exactly([LtiLineItem::SETUP_TYPE, nil],
                            ['Block', training_block.id], ['Block', exercise_block.id])
    end

    it 'PUTs a label change to LTIAAS when a block it owns is renamed' do
      stub_post_lineitem(label: 'Wk1 Get started')
      stub_post_lineitem(label: 'Wk1 Find sources',
                         lineitem_id: 'https://lms.example.com/li/find-sources')
      described_class.new(binding)

      put_stub = stub_request(:put,
                              "https://#{domain}/api/lineitems/" \
                              "#{CGI.escape('https://lms.example.com/li/find-sources')}")
                 .with(body: hash_including(label: 'Wk1 Bibliography exercise'))
                 .to_return(status: 200, body: '{}',
                            headers: { 'Content-Type' => 'application/json' })

      exercise_block.update!(title: 'Bibliography exercise')
      described_class.new(binding)

      expect(put_stub).to have_been_requested
    end
  end

  describe 'short exercise labels' do
    let(:gradebook_granularity) { 'per_block' }
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

    it 'labels the column with the operator short name, not the block title' do
      stub_post_lineitem(label: 'Wk1 Bibliography')
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
