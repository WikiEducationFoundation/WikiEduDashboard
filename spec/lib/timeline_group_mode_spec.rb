# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeline_group_mode"

describe TimelineGroupMode do
  let(:course) { create(:course) }
  let(:week) { create(:week, course:, order: 1) }

  # The two blocks the research-write wizard emits in individual and group
  # variants. Both share a title and differ only by training modules.
  def drafting_block(module_ids)
    create(:block, week:, title: 'Start drafting your contributions',
                   training_module_ids: module_ids, order: 1)
  end

  def mainspace_block(module_ids)
    create(:block, week:, title: 'Begin moving your work to Wikipedia',
                   training_module_ids: module_ids, order: 2)
  end

  it 'infers individual work from the drafting block' do
    drafting_block([30, 15])
    expect(described_class.new(course).logic_key).to eq('working_individually')
  end

  it 'infers group work from the drafting block' do
    drafting_block([31, 15])
    expect(described_class.new(course).logic_key).to eq('working_in_groups')
  end

  it 'infers from the mainspace block alone' do
    mainspace_block([32])
    expect(described_class.new(course).logic_key).to eq('working_individually')
  end

  it 'infers from two blocks that agree' do
    drafting_block([31, 15])
    mainspace_block([33])
    expect(described_class.new(course).logic_key).to eq('working_in_groups')
  end

  it 'ignores module order' do
    drafting_block([15, 30])
    expect(described_class.new(course).logic_key).to eq('working_individually')
  end

  it 'declines to answer when two blocks disagree' do
    drafting_block([30, 15])   # individual
    mainspace_block([33])      # groups
    expect(described_class.new(course).logic_key).to be_nil
  end

  it 'declines to answer when the timeline has no variant blocks' do
    create(:block, week:, title: 'Evaluate Wikipedia', order: 1)
    expect(described_class.new(course).logic_key).to be_nil
  end

  it 'declines to answer when a variant block has had its modules edited' do
    drafting_block([99])
    expect(described_class.new(course).logic_key).to be_nil
  end

  it 'declines to answer for a course with no timeline at all' do
    expect(described_class.new(course).logic_key).to be_nil
  end

  it 'is not fooled by a title match with no modules' do
    drafting_block([])
    expect(described_class.new(course).logic_key).to be_nil
  end
end
