# frozen_string_literal: true

require 'rails_helper'

describe CopyTrainingModuleToDraft do
  include_context 'training content fixture'

  let(:draft) { described_class.new('ponds').draft }

  it 'copies the module details and keeps its id' do
    expect(draft).to be_update
    expect(draft.name).to eq('Ponds')
    expect(draft.description).to eq("Learn about ponds.\n")
    expect(draft.estimated_ttc).to eq('10 minutes')
    expect(draft.module_id).to eq(91)
  end

  it 'copies each slide with the id of the slide it came from' do
    expect(draft.slides.first).to eq(
      'id' => 9101, 'slug' => 'pond-intro', 'title' => 'Pond intro',
      'content' => "Ponds are small.\n\nThey hold water.\n"
    )
    expect(draft.slides.pluck('id')).to eq([9101, 9102, 9103])
  end

  it 'snapshots the files it copied, keyed by repository path' do
    expect(draft.source.module_path).to eq("#{content_path}/modules/ponds.yml")
    expect(draft.source.files["#{content_path}/modules/ponds.yml"]).to eq(ponds_module_text)
    expect(draft.source.files["#{ponds_slides_path}/9103-pond-quiz.yml"]).to eq(pond_quiz_text)
  end

  it 'saves the draft under the module slug' do
    expect(draft.slug).to eq('ponds')
    expect(TrainingModuleDraft.find('ponds')).to be_update
  end

  it 'picks another draft slug when the module slug is taken' do
    TrainingModuleDraft.new(slug: 'ponds', name: 'Another').save
    expect(draft.slug).to eq('ponds-2')
  end

  it 'leaves out a listed slide that has no file' do
    write_training_file('modules/ponds.yml', "#{ponds_module_text}  - slug: missing-slide\n")
    expect(draft.slides.pluck('slug')).to eq(%w[pond-intro what-is-a-wetland pond-quiz])
  end

  it 'refuses a module with no file' do
    expect { described_class.new('../modules/ponds') }
      .to raise_error(CopyTrainingModuleToDraft::CopyError)
  end

  it 'refuses when trainings come from the wiki' do
    allow(Features).to receive(:wiki_trainings?).and_return(true)
    expect { described_class.new('ponds') }.to raise_error(CopyTrainingModuleToDraft::CopyError)
  end
end
