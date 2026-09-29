# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wizard_logic_state"

describe WizardLogicState do
  let(:course) { create(:course) }
  let(:state) { described_class.new(course) }

  describe 'sandbox mode' do
    it 'reads a course with no flag as using sandboxes, like the rest of the app' do
      expect(state.known).to include('no_sandboxes' => false, 'yes_sandboxes' => true)
    end

    it 'reads the no_sandboxes flag' do
      course.update(flags: { no_sandboxes: true })
      expect(state.known).to include('no_sandboxes' => true, 'yes_sandboxes' => false)
    end
  end

  describe 'peer review count' do
    it 'stays unknown when the flag was never written' do
      expect(state.known).not_to have_key('2_peer_reviewers')
    end

    it 'resolves every count once the flag exists' do
      course.update(flags: { peer_review_count: 2 })
      expect(state.known).to include('1_peer_reviewers' => false,
                                     '2_peer_reviewers' => true,
                                     '3_peer_reviewers' => false)
    end
  end

  describe 'tags' do
    it 'resolves both options of a panel from the tag that was written' do
      Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_in_groups')
      expect(state.known).to include('working_in_groups' => true,
                                     'working_individually' => false)
    end

    it 'resolves an untagged option of a panel whose chosen option was tagged' do
      # The generative_ai panel tags only "Yes"; seeing that tag also rules out
      # the "No" option, whose no_llm_training logic carries no tag of its own.
      Tag.create(course_id: course.id, key: 'generative_ai', tag: 'llm_training')
      expect(state.known).to include('llm_training' => true, 'no_llm_training' => false)
    end

    it 'leaves a panel unknown when no tag for it is present' do
      expect(state.known).not_to have_key('llm_training')
    end

    it 'handles the nonexclusive topics panel, which prefixes its tag keys' do
      Tag.create(course_id: course.id, key: 'topics-chemistry', tag: 'chemistry')
      expect(state.known).to include('chemistry_handout' => true, 'history_handout' => false)
    end

    # Most tags in production carry no key: `submitted`, `cloned`, `ta_support`
    # and everything an admin adds by hand are all written with key: nil. They
    # say nothing about the wizard, and must not break the panels that do.
    it 'ignores tags that carry no wizard key' do
      Tag.create(course_id: course.id, tag: 'submitted', key: nil)
      Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_in_groups')
      expect(state.known).to include('working_in_groups' => true,
                                     'working_individually' => false)
    end
  end

  describe '#verdict_for' do
    before { Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_in_groups') }

    it 'is :yes for a block with no conditions' do
      expect(state.verdict_for(if: [], unless: [])).to eq(:yes)
    end

    it 'is :yes when every if is met and no unless is' do
      expect(state.verdict_for(if: ['working_in_groups'], unless: ['no_sandboxes'])).to eq(:yes)
    end

    it 'is :no when an if is unmet' do
      expect(state.verdict_for(if: ['working_individually'], unless: [])).to eq(:no)
    end

    it 'is :no when an unless is met' do
      course.update(flags: { no_sandboxes: true })
      expect(state.verdict_for(if: ['working_in_groups'], unless: ['no_sandboxes'])).to eq(:no)
    end

    it 'is :unknown when any key involved was never persisted' do
      expect(state.verdict_for(if: ['copyedit'], unless: [])).to eq(:unknown)
    end

    it 'applies overrides, so a hypothetical flag flip can be evaluated' do
      conditions = { if: ['working_in_groups'], unless: ['no_sandboxes'] }
      expect(state.verdict_for(conditions, 'no_sandboxes' => true)).to eq(:no)
    end
  end

  describe '#unknown_keys' do
    it 'returns the candidate keys with no recoverable answer' do
      expect(state.unknown_keys(%w[no_sandboxes copyedit copyedit]))
        .to eq(['copyedit'])
    end
  end
end
