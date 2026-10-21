# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe ExportTrainingModuleUpdate do
  include_context 'training content fixture'

  let(:draft) { CopyTrainingModuleToDraft.new('ponds').draft }
  let(:module_path) { "#{content_path}/modules/ponds.yml" }
  let(:intro_path) { "#{ponds_slides_path}/9101-pond-intro.yml" }
  let(:wetland_path) { "#{ponds_slides_path}/9102-what-is-a-wetland.yml" }
  let(:quiz_path) { "#{ponds_slides_path}/9103-pond-quiz.yml" }

  def changed_files
    described_class.new(draft).changed_files
  end

  def slide(slug)
    draft.slides.find { |s| s['slug'] == slug }
  end

  it 'has no changes for an untouched copy' do
    expect(changed_files).to eq({})
  end

  it 'ignores differences in trailing whitespace' do
    slide('pond-intro')['content'] = "Ponds are small.\n\nThey hold water."
    expect(changed_files).to eq({})
  end

  it 'rewrites only the edited value of an edited slide' do
    slide('pond-quiz')['content'] = "Answer both questions.\n"
    expect(changed_files.keys).to eq([quiz_path])
    expect(changed_files[quiz_path])
      .to eq(pond_quiz_text.sub('Answer the question.', 'Answer both questions.'))
  end

  it 'updates the module details it edits and keeps the rest' do
    draft.description = "Learn all about ponds.\n"
    expect(changed_files.keys).to eq([module_path])
    expect(changed_files[module_path])
      .to eq(ponds_module_text.sub('Learn about ponds.', 'Learn all about ponds.'))
  end

  context 'with a new slide' do
    before do
      draft.slides.insert(1, { 'slug' => 'pond-life', 'title' => 'Pond life',
                               'content' => "Frogs.\n" })
    end

    it 'writes it with the next id in the module range, in the module slide directory' do
      new_path = "#{ponds_slides_path}/9104-pond-life.yml"
      expect(YAML.safe_load(changed_files[new_path]))
        .to eq('title' => 'Pond life', 'id' => 9104, 'content' => "Frogs.\n")
    end

    it 'skips ids already used by a loaded slide' do
      create(:training_slide, id: 9104, slug: 'loaded-elsewhere')
      expect(changed_files).to have_key("#{ponds_slides_path}/9105-pond-life.yml")
    end

    it 'lists it in the module in the same style as the other slides' do
      expect(changed_files[module_path]).to include(<<~YAML)
        slides:
          - slug: pond-intro # 9101
          - slug: pond-life # 9104
          - slug: what-is-a-wetland # 9102
      YAML
    end
  end

  it 'deletes the file of a removed slide' do
    draft.slides.reject! { |s| s['slug'] == 'pond-quiz' }
    expect(changed_files).to include(quiz_path => nil)
    expect(changed_files[module_path]).not_to include('pond-quiz')
  end

  it 'keeps the file of a removed slide that another module lists' do
    draft.slides.reject! { |s| s['slug'] == 'what-is-a-wetland' }
    expect(changed_files).not_to have_key(wetland_path)
    expect(changed_files[module_path]).not_to include('what-is-a-wetland')
  end

  it 'keeps the slug and file of a copied slide' do
    slide('pond-intro')['slug'] = 'about-ponds'
    expect(changed_files).to eq({})
  end

  it 'reports the status of each changed file' do
    slide('pond-intro')['title'] = 'Welcome to ponds'
    draft.slides.reject! { |s| s['slug'] == 'pond-quiz' }
    draft.slides << { 'slug' => 'pond-end', 'title' => 'The end', 'content' => 'Bye' }
    expect(described_class.new(draft).change_list).to contain_exactly(
      { 'path' => module_path, 'status' => 'modified' },
      { 'path' => intro_path, 'status' => 'modified' },
      { 'path' => "#{ponds_slides_path}/9104-pond-end.yml", 'status' => 'added' },
      { 'path' => quiz_path, 'status' => 'deleted' }
    )
  end

  describe '#zip_bytes' do
    let(:entries) do
      slide('pond-intro')['content'] = "Ponds are small.\n\nThey hold rain.\n"
      draft.slides.reject! { |s| s['slug'] == 'pond-quiz' }
      draft.slides << { 'slug' => 'pond-end', 'title' => 'The end', 'content' => "Bye\n" }
      read_zip(described_class.new(draft).zip_bytes)
    end

    def read_zip(bytes)
      entries = {}
      Zip::InputStream.open(StringIO.new(bytes)) do |io|
        while (entry = io.get_next_entry)
          entries[entry.name] = io.read.force_encoding('UTF-8')
        end
      end
      entries
    end

    it 'holds only the new and changed files, laid out like training_content/wiki_ed' do
      expect(entries.keys).to contain_exactly(
        'modules/ponds.yml', 'slides/91-ponds/9101-pond-intro.yml',
        'slides/91-ponds/9104-pond-end.yml'
      )
    end

    it 'holds the full new text of each file' do
      expect(entries['slides/91-ponds/9101-pond-intro.yml'])
        .to eq(pond_intro_text.sub('They hold water.', 'They hold rain.'))
      expect(entries['slides/91-ponds/9104-pond-end.yml'])
        .to eq("title: The end\nid: 9104\ncontent: |\n  Bye\n")
      expect(entries['modules/ponds.yml']).not_to include('pond-quiz')
    end
  end
end
