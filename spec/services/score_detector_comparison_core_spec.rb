# frozen_string_literal: true

require 'rails_helper'

describe ScoreDetectorComparisonCore do
  include_context 'detector comparison data'

  let(:pangram) { RevisionAiScore::PANGRAM_V4_1_KEY }
  let(:model_5) { RevisionAiScore::ORIGINALITY_5_KEY }
  let(:model_5_max) { RevisionAiScore::ORIGINALITY_5_MAX_KEY }
  let(:core_ids) { [human.id, generated.id, agpedia_article.id, article_after_term.id] }
  let(:pangram_response) do
    { 'version' => '4.1', 'prediction_short' => 'Human', 'fraction_ai' => 0.0,
      'fraction_ai_assisted' => 0.0, 'fraction_human' => 1.0,
      'windows' => [{ 'ai_assistance_score' => 0.01, 'is_humanized' => false }],
      'dashboard_link' => 'https://www.pangram.com/history/abc' }
  end

  def originality_response(model)
    { 'results' => { 'properties' => { 'publicLink' => 'https://app.originality.ai/share/x' },
                     'ai' => { 'model' => model, 'prediction_label' => 'human',
                               'ai_assisted_percent' => 3,
                               'sentences' => [{ 'ai_score' => 0.2 }] } } }
  end

  def step
    described_class.step(described_class.run['id'])
  end

  def run_steps(limit = 20)
    limit.times { break unless step }
  end

  before do
    stub_const('ScoreDetectorComparisonCore::CHUNK_SIZE', 2)
    allow(ScoreDetectorComparisonCoreWorker).to receive(:perform_async).and_return('jid')
    allow(OriginalityApi).to receive(:credit_balance).and_return(1_000)
    allow(AiDetector.for(pangram).client).to receive(:inference).and_return(pangram_response)
    allow(AiDetector.for(model_5).client).to receive(:inference)
      .and_return(originality_response('model-5.0'))
    allow(AiDetector.for(model_5_max).client).to receive(:inference)
      .and_return(originality_response('model-5.0-max'))
  end

  describe '.units' do
    it 'takes the known-human texts and the topics dataset, one unit per distinct text' do
      AiDetectionSample.create!(sample_name: 'terms_baseline_extra', plain_text: human_text,
                                ground_truth: 'human', provenance: 'pre_llm_term',
                                url: 'https://en.wikipedia.org/w/index.php?diff=21&oldid=11')

      expect(described_class.units.map(&:id)).to eq(core_ids.sort)
    end
  end

  describe '.plan' do
    it 'reports pending texts and credits per detector without calling any' do
      expect(AiDetector.for(pangram).client).not_to receive(:inference)

      report = described_class.plan

      expect(report[pangram][:pending_units]).to eq(4)
      expect(report[model_5_max][:pending_units]).to eq(4)
      expect(report['originality_credit_balance']).to eq(1_000)
    end
  end

  describe '.start' do
    it 'records the run and queues the first chunk' do
      status = described_class.start(max_originality_credits: 100)

      expect(ScoreDetectorComparisonCoreWorker)
        .to have_received(:perform_async).with(described_class.run['id'])
      expect(status).to include('state' => 'running', 'start_balance' => 1_000,
                                'detectors' => [pangram, model_5, model_5_max],
                                'max_originality_credits' => 100)
      expect(status).not_to have_key('unit_ids')
      expect(described_class.run['unit_ids']).to eq(core_ids.sort)
    end

    it 'refuses the production key' do
      expect { described_class.start(max_originality_credits: 100, detectors: ['Pangram 4']) }
        .to raise_error(ArgumentError, /Pangram 4/)
      expect(ScoreDetectorComparisonCoreWorker).not_to have_received(:perform_async)
    end
  end

  describe '.step' do
    it 'scores each detector in turn, a chunk at a time, then finishes' do
      described_class.start(max_originality_credits: 100)

      expect(step).to be(true)
      expect(RevisionAiScore.where(check_type: pangram, sample_id: core_ids).count).to eq(2)
      expect(RevisionAiScore.where(check_type: model_5).count).to eq(0)

      run_steps

      core_ids.each do |id|
        expect(RevisionAiScore.where(sample_id: id).pluck(:check_type))
          .to include(pangram, model_5, model_5_max)
      end
      expect(described_class.status).to include('state' => 'finished', 'scored' => 12,
                                                'failed' => 0)
      credits = AiDetectionSample.where(id: core_ids).sum { |unit| unit.word_count.fdiv(100).ceil }
      expect(described_class.status['phases'][model_5_max])
        .to include('scored' => 4, 'estimated_credits' => credits)
    end

    it 'does nothing once the run is no longer running' do
      described_class.start(max_originality_credits: 100)
      described_class.stop

      expect(step).to be(false)
      expect(described_class.status).to include('state' => 'stopped',
                                                'message' => 'Stopped on request')
      expect(step).to be(false)
      expect(RevisionAiScore.where(check_type: pangram).count).to eq(0)
    end

    it 'stops when a vendor answers with another model version' do
      allow(AiDetector.for(pangram).client).to receive(:inference)
        .and_raise(PangramApi::ModelMismatch, 'expected Pangram 4.1 but got "4.2"')
      described_class.start(max_originality_credits: 100)

      expect(step).to be(false)
      expect(described_class.status).to include('state' => 'stopped')
      expect(described_class.status['message']).to include('ModelMismatch', '4.2')
      expect(RevisionAiScore.where(check_type: pangram).count).to eq(0)
    end

    it 'stops after too many failed calls in a row' do
      stub_const('ScoreDetectorComparisonCore::FAILURE_LIMIT', 3)
      allow(AiDetector.for(pangram).client).to receive(:inference)
        .and_raise(PangramApi::TaskTimeout, 'unfinished')
      described_class.start(max_originality_credits: 100)

      run_steps

      expect(described_class.status).to include('state' => 'stopped', 'failed' => 4)
      expect(described_class.status['message']).to include('failed calls in a row')
    end

    it 'stops when Originality spends more than the cap' do
      described_class.start(max_originality_credits: 8)
      balances = [1_000, 1_000, 995, 989]
      allow(described_class).to receive(:originality_balance) { balances.shift || 989 }

      run_steps

      expect(described_class.status['state']).to eq('stopped')
      expect(described_class.status['message']).to include('Spent 11 Originality credits')
    end

    it 'stops when a detector bills well above its estimate' do
      stub_const('ScoreDetectorComparisonCore::BILLING_CHECK_UNITS', 2)
      described_class.start(max_originality_credits: 1_000,
                            detectors: [model_5_max])
      # Phase start, then after the first chunk: 2 texts billed 100 credits.
      balances = [1_000, 900]
      allow(described_class).to receive(:originality_balance) { balances.shift || 900 }

      run_steps

      expect(described_class.status['state']).to eq('stopped')
      expect(described_class.status['message'])
        .to match(/Originality 5.0 Max spent 100 credits on 2 texts, estimated \d+;/)
      expect(RevisionAiScore.where(check_type: model_5_max).count).to eq(2)
    end
  end

  describe 'run control' do
    it 'refuses a second start while a run is live, unless forced' do
      described_class.start(max_originality_credits: 100, detectors: [pangram])
      first = described_class.run['id']

      expect { described_class.start(max_originality_credits: 100, detectors: [pangram]) }
        .to raise_error(ArgumentError, /a run is running/)

      described_class.start(max_originality_credits: 100, detectors: [pangram], force: true)
      expect(described_class.run['id']).not_to eq(first)
      expect(described_class.step(first)).to be(false) # the replaced run's job exits
    end

    it 'keeps a stop requested while a chunk is being scored' do
      described_class.start(max_originality_credits: 100, detectors: [pangram])
      allow(AiDetector.for(pangram).client).to receive(:inference) do
        described_class.stop # from a console, mid-chunk
        pangram_response
      end

      expect(step).to be(false)
      expect(described_class.status).to include('state' => 'stopped',
                                                'message' => 'Stopped on request')
    end

    it 'does not save over a run that replaced it mid-chunk' do
      described_class.start(max_originality_credits: 100, detectors: [pangram])
      first = described_class.run['id']
      allow(AiDetector.for(pangram).client).to receive(:inference) do
        described_class.save_run(described_class.run.merge('id' => 'replacement'))
        pangram_response
      end

      expect(described_class.step(first)).to be(false)
      expect(described_class.run['id']).to eq('replacement')
      expect(described_class.status['scored']).to eq(0)
    end

    it 'does not read the Originality balance for a Pangram-only run' do
      expect(OriginalityApi).not_to receive(:credit_balance)

      described_class.start(max_originality_credits: 100, detectors: [pangram])
      run_steps

      expect(described_class.status).to include('state' => 'finished', 'start_balance' => nil)
    end

    it 'records a run whose first job could not be queued as stopped' do
      allow(ScoreDetectorComparisonCoreWorker).to receive(:perform_async).and_return(nil)

      expect { described_class.start(max_originality_credits: 100, detectors: [pangram]) }
        .to raise_error(/not queued/)
      expect(described_class.status['state']).to eq('stopped')
    end
  end

  describe 'failed calls' do
    it 'does not resend a text that failed during this run, and retries it on the next start' do
      calls = Hash.new(0)
      allow(AiDetector.for(pangram).client).to receive(:inference) do |text|
        calls[text] += 1
        raise PangramApi::TaskFailed, 'task failed' if text == human.plain_text

        pangram_response
      end
      described_class.start(max_originality_credits: 100, detectors: [pangram])
      run_steps

      expect(calls[human.plain_text]).to eq(1)
      expect(described_class.status).to include('state' => 'finished', 'scored' => 3,
                                                'failed' => 1)

      described_class.start(max_originality_credits: 100, detectors: [pangram])
      run_steps
      expect(calls[human.plain_text]).to eq(2)
    end

    it 'stops once one detector has failed too often' do
      stub_const('ScoreDetectorComparisonCore::MAX_FAILURES', 3)
      stub_const('ScoreDetectorComparisonCore::FAILURE_LIMIT', 100)
      allow(AiDetector.for(pangram).client).to receive(:inference) do |text|
        raise PangramApi::TaskFailed, 'task failed' unless text == generated.plain_text

        pangram_response
      end
      described_class.start(max_originality_credits: 100, detectors: [pangram])

      run_steps

      expect(described_class.status['state']).to eq('stopped')
      expect(described_class.status['message']).to eq('3 failed Pangram 4.1 calls')
    end
  end
end
