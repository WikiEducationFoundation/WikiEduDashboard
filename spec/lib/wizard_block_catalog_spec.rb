# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wizard_block_catalog"

describe WizardBlockCatalog do
  describe 'every wizard content file' do
    wizard_ids = WizardTimelineManager::VALID_WIZARD_IDS

    wizard_ids.each do |wizard_id|
      it "gives every #{wizard_id} block an id" do
        ids = described_class.new(wizard_id).blocks.map { |block| block[:id] }
        expect(ids).to all(be_present)
      end

      it "gives every #{wizard_id} block a unique id" do
        ids = described_class.new(wizard_id).blocks.map { |block| block[:id] }
        expect(ids.uniq).to eq(ids)
      end
    end
  end

  describe 'researchwrite' do
    let(:catalog) { described_class.new('researchwrite') }

    it 'flattens every block in the content file' do
      expect(catalog.blocks.count).to eq(45)
    end

    it 'records the conditions a block depends on' do
      entry = catalog.find('start_drafting_individually')
      expect(entry[:conditions]).to eq(if: ['working_individually'], unless: ['no_sandboxes'])
    end

    it 'records an unconditional block with empty conditions' do
      entry = catalog.find('evaluate_wikipedia')
      expect(entry[:conditions]).to eq(if: [], unless: [])
    end

    it 'carries the content needed to build a block' do
      entry = catalog.find('start_editing_live')
      expect(entry).to include(title: 'Start editing your article',
                               kind: Block::KINDS['assignment'],
                               training_module_ids: [64, 15],
                               week: 5)
      expect(entry[:content]).to include('Editing Wikipedia')
    end

    it 'fills in default points for a graded block with no explicit value' do
      allow(YAML).to receive(:safe_load_file).and_return(
        'essentials' => [{ 'blocks' => [{ 'id' => 'x', 'title' => 'X', 'graded' => true }] }]
      )
      expect(catalog.find('x')[:points]).to eq(Block::DEFAULT_POINTS)
    end

    it 'keeps an explicit points value' do
      expect(catalog.find('start_drafting_individually')[:points]).to eq(20)
    end

    it 'leaves points nil for an ungraded block' do
      expect(catalog.find('evaluate_wikipedia')[:points]).to be_nil
    end

    it 'marks handouts blocks as not insertable, since their content is generated' do
      expect(catalog.find('handouts_from_list')[:insertable]).to be false
    end

    it 'marks ordinary blocks as insertable' do
      expect(catalog.find('evaluate_wikipedia')[:insertable]).to be true
    end

    it 'collects every logic key any block depends on' do
      expect(catalog.condition_keys).to include('no_sandboxes', 'working_in_groups', 'copyedit')
    end

    it 'finds the blocks that depend on a given logic key, either way round' do
      ids = catalog.conditional_on('no_sandboxes').map { |block| block[:id] }
      expect(ids).to contain_exactly('keeping_track_no_sandboxes', 'keeping_track_sandboxes',
                                     'start_drafting_individually', 'start_drafting_in_groups',
                                     'start_editing_live', 'drafting_new_article_in_sandbox',
                                     'publishing_new_article_live',
                                     'moving_to_mainspace_individually',
                                     'moving_to_mainspace_in_groups')
    end

    it 'rejects a wizard that does not exist' do
      expect { described_class.new('nope') }
        .to raise_error(WizardTimelineManager::InvalidWizardError)
    end
  end
end
