# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/metrics_glossary"
require "#{Rails.root}/lib/metrics_glossary/checker"

describe MetricsGlossary do
  # The drift checks for the real glossary in docs/metrics/. When one fails,
  # its message says what to update; `bin/rails metrics:check` prints the same.
  describe 'the glossary in docs/metrics' do
    let(:checker) { MetricsGlossary::Checker.new }

    it 'is well formed' do
      expect(checker.schema_errors).to eq([])
    end

    it 'points at code, translation keys and columns that exist' do
      expect(checker.reference_errors).to eq([])
    end

    it 'accounts for every metric-like column and translation key' do
      expect(checker.coverage_errors).to eq([])
    end

    it 'has been checked against the current version of every formula' do
      expect(checker.fingerprint_errors).to eq([])
    end
  end

  context 'with a fixture glossary' do
    let(:dir) { Dir.mktmpdir }
    let(:metric) do
      { 'name' => 'Words Added', 'summary' => 'Words.', 'explanation' => 'Characters / 5.175.',
        'implementations' => [{ 'ruby' => 'WordCount.from_characters',
                                'path' => 'lib/word_count.rb', 'formula' => true }],
        'surfaces' => [{ 'i18n' => 'metrics.word_count' }],
        'columns' => ['courses.character_sum'] }
    end
    let(:divergences) { {} }
    let(:sections) do
      { 'overview' => { 'title' => 'Course overview', 'metrics' => ['words_added'] } }
    end
    # Written when first used, so examples can adjust `metric`, `divergences`
    # and `sections` beforehand.
    let(:glossary) do
      write_yaml('contributions', 'metrics' => { 'words_added' => metric },
                                  'divergences' => divergences)
      write_yaml('layout', 'sections' => sections)
      described_class.new(dir)
    end
    let(:fingerprints) do
      MetricsGlossary::Fingerprints.new(glossary, File.join(dir, 'fingerprints.yml'))
    end
    let(:coverage) do
      instance_double(MetricsGlossary::Coverage,
                      metric_columns: Set['courses.character_sum', 'courses.view_sum'],
                      metric_i18n_keys: Set['metrics.word_count'],
                      schema_columns: Set['courses.character_sum', 'courses.view_sum'],
                      i18n_keys: Set['metrics.word_count'])
    end
    let(:checker) do
      MetricsGlossary::Checker.new(glossary, coverage:, fingerprints:,
                                             unclaimed_path: File.join(dir, 'unclaimed.yml'))
    end

    def write_yaml(name, data)
      File.write(File.join(dir, "#{name}.yml"), data.to_yaml)
    end

    before do
      write_yaml('unclaimed', 'pending' => { 'columns' => ['courses.view_sum'] })
    end

    after { FileUtils.remove_entry(dir) }

    it 'finds nothing wrong with a correct entry once its formula is accepted' do
      fingerprints.write!
      expect(checker.errors).to eq([])
    end

    it 'reports a code pointer that no longer resolves' do
      metric['implementations'] = [{ 'ruby' => 'WordCount.from_words',
                                     'path' => 'lib/word_count.rb' }]
      expect(checker.reference_errors.join).to include('WordCount.from_words')
    end

    it 'reports translation keys and columns that no longer exist' do
      metric['surfaces'] = [{ 'i18n' => 'metrics.no_such_key' }]
      metric['columns'] = ['courses.no_such_column']
      expect(checker.reference_errors).to contain_exactly(
        'words_added: no translation key metrics.no_such_key in en.yml',
        'words_added: no column courses.no_such_column in db/schema.rb'
      )
    end

    it 'reports a formula that changed since its entry was last checked' do
      File.write(File.join(dir, 'fingerprints.yml'),
                 { 'WordCount.from_characters' => 'out-of-date' }.to_yaml)
      expect(checker.fingerprint_errors.join)
        .to include('WordCount.from_characters changed since the glossary entries that ' \
                    'point at it (words_added)')
    end

    # A throwaway constant, since restoring a stubbed real one moves its
    # source location into rspec-mocks for the rest of the run.
    it 'reports a constant whose value changed since its entries were last checked' do
      stub_const('MetricsGlossaryFixture::RATIO', 5.175)
      metric['implementations'] << { 'ruby' => 'MetricsGlossaryFixture::RATIO' }
      fingerprints.write!
      stub_const('MetricsGlossaryFixture::RATIO', 5.0)
      rechecked = MetricsGlossary::Fingerprints.new(glossary, File.join(dir, 'fingerprints.yml'))
      expect(rechecked.changed).to eq(['MetricsGlossaryFixture::RATIO'])
    end

    it 'does not fingerprint classes' do
      metric['implementations'] << { 'ruby' => 'Course' }
      expect(fingerprints.current.keys).to eq(['WordCount.from_characters'])
    end

    it 'reports a metric-like column that is neither documented nor unclaimed' do
      write_yaml('unclaimed', {})
      expect(checker.coverage_errors.join)
        .to include('The column courses.view_sum looks like a metric')
    end

    it 'requires a reason for each ignored column' do
      write_yaml('unclaimed', 'ignored' => { 'columns' => { 'courses.view_sum' => '' } })
      expect(checker.coverage_errors.join).to include('needs a reason')
    end

    context 'when a divergence is malformed' do
      let(:divergences) do
        { 'words-rounding' => { 'title' => 'Rounding', 'status' => 'maybe', 'colour' => 'red',
                                'metrics' => %w[words_added no_such_metric] } }
      end

      it 'reports each problem' do
        expect(checker.schema_errors).to include(
          'words-rounding: unknown field colour',
          'words-rounding: missing description',
          'words-rounding: status must be one of undecided, intentional, bug',
          'words-rounding: metric no_such_metric doesn\'t exist'
        )
      end
    end

    it 'reports a metric that is not in any section of the layout' do
      sections['overview']['metrics'] = []
      expect(checker.schema_errors).to include(
        "words_added: isn't placed in any section of layout.yml"
      )
    end

    it 'reports a note for a metric that its own section explains' do
      sections['overview']['notes'] = { 'words_added' => { 'label' => 'Words', 'text' => 'Same.' } }
      expect(checker.schema_errors).to include(
        'layout.yml overview: note for words_added, which this section already explains'
      )
    end

    it 'reports a missing visual' do
      sections['overview']['visual'] = 'no_such_visual'
      expect(checker.schema_errors).to include(
        'layout.yml overview: no visual partial _no_such_visual.html.haml'
      )
    end

    describe '#visible_sections' do
      let(:sections) do
        { 'overview' => { 'title' => 'Course overview', 'metrics' => %w[words_added secret],
                          'notes' => {} },
          'students' => { 'title' => 'Students tab', 'metrics' => ['pe_only'],
                          'notes' => { 'secret' => { 'label' => 'Secret',
                                                     'text' => 'Hidden.' } } } }
      end

      before do
        write_yaml('participants',
                   'metrics' => { 'secret' => metric.deep_dup.merge('audience' => 'admin'),
                                  'pe_only' => metric.deep_dup.merge('deployments' => ['pe']) })
      end

      def visible_keys(**viewer)
        glossary.visible_sections(**viewer).flat_map(&:metrics).map(&:key)
      end

      it 'drops notes on entries the viewer cannot see, and sections left empty' do
        expect(glossary.visible_sections(admin: false, deployment: 'wiki_ed').map(&:key))
          .to eq(['overview'])
        expect(glossary.visible_sections(admin: true, deployment: 'pe').last.notes.keys)
          .to eq(['secret'])
      end

      it 'hides admin-only entries from everyone else' do
        expect(visible_keys(admin: false, deployment: 'wiki_ed')).to eq(['words_added'])
        expect(visible_keys(admin: true, deployment: 'wiki_ed')).to eq(%w[words_added secret])
      end

      it 'shows entries only on the deployments they apply to' do
        expect(visible_keys(admin: false, deployment: 'pe')).to eq(%w[words_added pe_only])
      end
    end
  end
end
