# frozen_string_literal: true

# A small training_content tree on disk, standing in for training_content/wiki_ed
# in specs of the training module composer's update drafts. Module `ponds`
# (id 91) lists three slides; module `wetlands` also lists `what-is-a-wetland`,
# whose file lives in ponds' slide directory. Composer drafts are written to a
# scratch directory as well.
RSpec.shared_context 'training content fixture' do
  let(:fixture_root) { Rails.root.join('tmp', "training_content_fixture_#{SecureRandom.hex(4)}") }
  let(:content_root) { fixture_root.join('training') }
  let(:content_path) { content_root.relative_path_from(Rails.root).to_s }
  let(:ponds_slides_path) { "#{content_path}/slides/91-ponds" }

  let(:ponds_module_text) do
    <<~YAML
      name: 'Ponds'
      id: 91
      description: |
        Learn about ponds.
      estimated_ttc: 10 minutes
      # Slides are listed in order.
      slides:
        - slug: pond-intro # 9101
        - slug: what-is-a-wetland # 9102
        - slug: pond-quiz # 9103
    YAML
  end

  let(:pond_intro_text) do
    <<~YAML
      ---
      title: "Pond intro"
      id: 9101
      summary: A first look
      content: |
        Ponds are small.

        They hold water.
    YAML
  end

  let(:pond_quiz_text) do
    <<~YAML
      title: Pond quiz
      id: 9103
      assessment:
        question: How big is a pond?
        correct_answer_id: 1
      content: |
        Answer the question.
      translations:
        es:
          title: Prueba
    YAML
  end

  def write_training_file(relative_path, text)
    path = content_root.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    path.write(text)
  end

  before do
    write_training_file('modules/ponds.yml', ponds_module_text)
    write_training_file('modules/wetlands.yml', <<~YAML)
      name: Wetlands
      id: 92
      description: Wetland basics.
      slides:
      - slug: what-is-a-wetland
    YAML
    write_training_file('slides/91-ponds/9101-pond-intro.yml', pond_intro_text)
    write_training_file('slides/91-ponds/9102-what-is-a-wetland.yml', <<~YAML)
      title: What is a wetland?
      id: 9102
      content: |
        Wetlands are wet.
    YAML
    write_training_file('slides/91-ponds/9103-pond-quiz.yml', pond_quiz_text)

    allow(TrainingBase).to receive(:base_path).and_return(content_root.to_s)
    stub_const('TrainingModuleDraft::DIRNAME',
               fixture_root.join('drafts').relative_path_from(Rails.root).to_s)
  end

  after { FileUtils.rm_rf(fixture_root) }
end
