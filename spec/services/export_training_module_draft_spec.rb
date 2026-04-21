# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe ExportTrainingModuleDraft do
  let(:tmp_dir) { Rails.root.join('tmp', 'export_training_module_draft_spec') }

  before do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    stub_const('TrainingModuleDraft::DIRNAME', tmp_dir.relative_path_from(Rails.root).to_s)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  def read_zip(bytes)
    entries = {}
    Zip::InputStream.open(StringIO.new(bytes)) do |io|
      while (entry = io.get_next_entry)
        entries[entry.name] = io.read
      end
    end
    entries
  end

  let(:draft) do
    allow(TrainingModule).to receive(:pluck).with(:id).and_return([1, 2, 74])
    TrainingModuleDraft.new(
      slug: 'my-new-module',
      name: 'My new module',
      description: 'A description',
      estimated_ttc: '15-25 minutes',
      slides: [
        { 'slug' => 'intro', 'title' => 'Introduction', 'content' => "Hello\n" },
        { 'slug' => 'next-step', 'title' => 'Next step', 'content' => "World\n" }
      ]
    ).save
  end

  it 'builds a module yml at modules/<slug>.yml' do
    entries = read_zip(described_class.new(draft).zip_bytes)
    expect(entries).to have_key('modules/my-new-module.yml')
    module_data = YAML.safe_load(entries['modules/my-new-module.yml'])
    expect(module_data['name']).to eq('My new module')
    expect(module_data['id']).to eq(draft.module_id)
    expect(module_data['slides']).to eq([{ 'slug' => 'intro' }, { 'slug' => 'next-step' }])
  end

  it 'writes slide ymls in the production slides/<id>-<slug>/ layout' do
    entries = read_zip(described_class.new(draft).zip_bytes)
    expect(entries).to have_key("slides/#{draft.module_id}-my-new-module/7501-intro.yml")
    expect(entries).to have_key("slides/#{draft.module_id}-my-new-module/7502-next-step.yml")
  end

  it 'writes slide bodies with derived ids' do
    entries = read_zip(described_class.new(draft).zip_bytes)
    slide = YAML.safe_load(entries["slides/#{draft.module_id}-my-new-module/7501-intro.yml"])
    expect(slide).to include('id' => 7501, 'title' => 'Introduction',
                             'summary' => '', 'content' => "Hello\n")
  end

  it 'emits empty strings for nil module fields so Redcarpet does not crash' do
    allow(TrainingModule).to receive(:pluck).with(:id).and_return([])
    bare = TrainingModuleDraft.new(slug: 'bare', name: 'Bare',
                                   slides: [{ 'slug' => 's', 'title' => 'T',
                                              'content' => 'C' }]).save
    entries = read_zip(described_class.new(bare).zip_bytes)
    module_data = YAML.safe_load(entries['modules/bare.yml'])
    expect(module_data['description']).to eq('')
    expect(module_data['estimated_ttc']).to eq('')
  end

  it 'pads slide ids to 4 digits in filenames' do
    allow(TrainingModule).to receive(:pluck).with(:id).and_return([])
    small_draft = TrainingModuleDraft.new(
      slug: 'tiny',
      name: 'Tiny',
      slides: [{ 'slug' => 's1', 'title' => 'S1', 'content' => '' }]
    ).save
    entries = read_zip(described_class.new(small_draft).zip_bytes)
    # module_id 1, slide 1 -> slide_id 101 -> filename padded to 0101
    expect(entries.keys).to include(a_string_matching(%r{slides/1-tiny/0101-s1\.yml}))
  end

  it 'uses a dated zip filename' do
    export = described_class.new(draft)
    expect(export.filename).to match(/\Amy-new-module-\d{8}\.zip\z/)
  end

  describe '.slide_slug_collisions' do
    it 'returns slugs that collide with existing TrainingSlides' do
      create(:training_slide, slug: 'intro')
      expect(described_class.slide_slug_collisions(draft)).to eq(['intro'])
    end

    it 'returns [] when there are no collisions' do
      expect(described_class.slide_slug_collisions(draft)).to eq([])
    end
  end
end
