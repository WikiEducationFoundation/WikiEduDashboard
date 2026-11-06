# frozen_string_literal: true

require 'rails_helper'

describe FindMissingExpectedModules do
  subject(:missing) { described_class.new(course).missing }

  let(:course) { create(:course) }
  let(:week) { create(:week, course:) }
  # Every expected module except the drafting / moving / working live choice.
  let(:core_modules) { [1, 28, 7, 71, 15, 72, 73] }

  def add_modules(ids)
    create(:block, week:, training_module_ids: ids)
  end

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    Tag.create(course_id: course.id, key: 'index', tag: 'research_write_assignment')
  end

  it 'reports nothing for a sandbox timeline with every expected module' do
    add_modules(core_modules + [30, 32])
    expect(missing).to be_empty
  end

  it 'reports nothing for a working-live timeline with every expected module' do
    add_modules(core_modules + [64])
    expect(missing).to be_empty
  end

  it 'accepts either version of drafting and moving' do
    add_modules(core_modules + [31, 33])
    expect(missing).to be_empty
  end

  it 'reports a removed module' do
    add_modules((core_modules - [15]) + [64])
    expect(missing).to eq([[15]])
  end

  it 'counts modules spread across blocks' do
    add_modules(core_modules.first(4))
    add_modules(core_modules.drop(4) + [64])
    expect(missing).to be_empty
  end

  it 'reports moving when only drafting is present' do
    add_modules(core_modules + [30])
    expect(missing).to eq([[32, 33]])
  end

  it 'reports drafting and moving when neither they nor working live are present' do
    add_modules(core_modules)
    expect(missing).to eq([[30, 31], [32, 33]])
  end

  it 'reports everything for an empty timeline' do
    expect(missing.size).to eq(9)
  end

  it 'skips courses without the research-and-write tag' do
    Tag.where(course_id: course.id).destroy_all
    expect(missing).to be_empty
  end

  it 'skips courses that are not ClassroomProgramCourses' do
    allow(course).to receive(:is_a?).with(ClassroomProgramCourse).and_return(false)
    expect(missing).to be_empty
  end

  it 'skips Programs & Events Dashboard' do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    expect(missing).to be_empty
  end

  describe '#missing_module_names' do
    before { TrainingModule.load_all }

    it 'names the modules that would satisfy each unmet expectation' do
      add_modules(core_modules + [30])
      names = described_class.new(course).missing_module_names
      expect(names).to eq([['Moving work out of the sandbox', 'Moving group work live']])
    end
  end
end
