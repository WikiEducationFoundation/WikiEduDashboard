# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/evaluation/extraction_evaluation"

describe ClaimVerification::Evaluation::ExtractionEvaluation do
  context 'with the seed dataset' do
    let(:evaluation) { described_class.new }

    it 'scores the current extractor perfectly' do
      expect(evaluation.summary).to eq(
        claim_precision: 1.0, claim_recall: 1.0, claim_f1: 1.0,
        citation_recall: 1.0
      )
    end

    it 'reports per-case detail' do
      result = evaluation.case_results.first
      expect(result[:name]).to eq('third_place_diff')
      expect(result[:claims][:missing]).to be_empty
      expect(result[:claims][:unexpected]).to be_empty
    end
  end

  context 'with an extractor that misses and over-extracts' do
    let(:dataset_path) { Rails.root.join('tmp/extraction_eval_test/cases.yml') }
    let(:broken_extractor) do
      Class.new do
        attr_reader :claims, :citations

        def initialize(_html)
          @claims = [
            ClaimVerification::Claim.new(sentence: 'Real claim.',
                                         ref_ids: ['cite_note-1'], context: 'Real claim.'),
            ClaimVerification::Claim.new(sentence: 'Spurious claim.',
                                         ref_ids: ['cite_note-1'], context: 'Spurious claim.')
          ]
          @citations = []
        end
      end
    end

    before do
      FileUtils.mkdir_p(dataset_path.dirname)
      File.write(dataset_path.dirname.join('case.html'), '<p></p>')
      File.write(dataset_path, <<~YAML)
        - name: test_case
          html_file: case.html
          claims:
            - sentence_includes: Real claim
              ref_ids: [cite_note-1]
            - sentence_includes: Missed claim
              ref_ids: [cite_note-2]
          citations:
            - ref_id: cite_note-1
              text_includes: Author
      YAML
    end

    after { FileUtils.rm_rf(dataset_path.dirname) }

    let(:evaluation) do
      described_class.new(dataset_path: dataset_path.to_s,
                          extractor_class: broken_extractor)
    end

    it 'counts missing claims against recall' do
      expect(evaluation.summary[:claim_recall]).to eq(0.5)
      expect(evaluation.case_results.first[:claims][:missing]).to eq(['Missed claim'])
    end

    it 'counts unexpected claims against precision' do
      expect(evaluation.summary[:claim_precision]).to eq(0.5)
      expect(evaluation.case_results.first[:claims][:unexpected]).to eq(['Spurious claim.'])
    end

    it 'counts missing citations' do
      expect(evaluation.summary[:citation_recall]).to eq(0.0)
      expect(evaluation.case_results.first[:citations][:missing]).to eq(['cite_note-1'])
    end
  end
end
