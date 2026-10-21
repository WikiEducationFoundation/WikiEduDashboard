# frozen_string_literal: true

require 'rails_helper'

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

  it 'renames the file of a slide whose slug changed' do
    slide('pond-intro')['slug'] = 'about-ponds'
    expect(changed_files).to include(intro_path => nil)
    expect(changed_files["#{ponds_slides_path}/9101-about-ponds.yml"]).to eq(pond_intro_text)
    expect(changed_files[module_path]).to include('  - slug: about-ponds # 9101')
  end

  it 'does not rename a slide that another module lists' do
    slide('what-is-a-wetland')['slug'] = 'wetlands-defined'
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

  describe '#patch' do
    let(:patch) do
      slide('pond-intro')['content'] = "Ponds are small.\n\nThey hold rain.\n"
      draft.slides.reject! { |s| s['slug'] == 'pond-quiz' }
      draft.slides << { 'slug' => 'pond-end', 'title' => 'The end', 'content' => "Bye\n" }
      described_class.new(draft).patch(author_name: 'Pat Admin', author_email: 'pat@example.org')
    end

    it 'is an email that git am turns into a commit by the drafting admin' do
      expect(patch).to include('From: Pat Admin <pat@example.org>')
      expect(patch).to include('Subject: [PATCH] Update ponds training module')
    end

    it 'applies to the copied files and produces the draft' do
      Dir.mktmpdir do |dir|
        draft.source.files.each do |path, text|
          FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
          File.write(File.join(dir, path), text)
        end
        _, error, status = Open3.capture3('git', 'apply', chdir: dir, stdin_data: patch)
        expect(status).to be_success, error
        expect(File.read(File.join(dir, intro_path))).to include('They hold rain.')
        expect(File.exist?(File.join(dir, quiz_path))).to be(false)
        expect(File.read(File.join(dir, "#{ponds_slides_path}/9104-pond-end.yml")))
          .to eq("title: The end\nid: 9104\ncontent: |\n  Bye\n")
      end
    end
  end
end
