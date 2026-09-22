# frozen_string_literal: true

require 'rails_helper'

describe AiDetectionSample do
  let(:text) { (['Some human prose about a river crossing.'] * 20).join(' ') }

  it 'derives the text hash and word count before saving' do
    unit = described_class.create!(sample_name: 'test', plain_text: text)

    expect(unit.text_sha256).to eq(Digest::SHA256.hexdigest(text))
    expect(unit.word_count).to eq(140)
  end

  it 'requires a sample name and text' do
    expect(described_class.new(plain_text: text)).not_to be_valid
    expect(described_class.new(sample_name: 'test')).not_to be_valid
  end

  it 'only accepts known ground truth labels, with nil meaning unknown' do
    unit = described_class.new(sample_name: 'test', plain_text: text, ground_truth: 'maybe')
    expect(unit).not_to be_valid
    unit.ground_truth = AiDetectionSample::AI_ASSISTED
    expect(unit).to be_valid
    unit.ground_truth = nil
    expect(unit).to be_valid
  end

  it 'leaves provenance free-form' do
    unit = described_class.new(sample_name: 'test', plain_text: text, provenance: 'agpedia dump')
    expect(unit).to be_valid
  end

  it 'requires factors to be flat name-value pairs' do
    unit = described_class.new(sample_name: 'test', plain_text: text,
                               factors: { 'topic' => 'Bees', 'model' => 'gpt-5' })
    expect(unit).to be_valid
    unit.factors = { 'topic' => %w[Bees Wasps] }
    expect(unit).not_to be_valid
  end

  describe '#linked_by' do
    it 'finds the other units in the sample sharing a factor value' do
      human = described_class.create!(sample_name: 'test', plain_text: text,
                                      factors: { 'topic' => 'Bees', 'author' => 'student' })
      ai = described_class.create!(sample_name: 'test', plain_text: "#{text} AI",
                                   factors: { 'topic' => 'Bees', 'model' => 'gpt-5' })
      described_class.create!(sample_name: 'test', plain_text: "#{text} other",
                              factors: { 'topic' => 'Wasps' })
      described_class.create!(sample_name: 'elsewhere', plain_text: "#{text} far",
                              factors: { 'topic' => 'Bees' })

      expect(human.linked_by(:topic)).to eq([ai])
      expect(ai.linked_by('model')).to be_empty
      expect(human.linked_by(:missing)).to be_empty
    end
  end

  describe '#scored_with?' do
    let(:unit) { described_class.create!(sample_name: 'test', plain_text: text) }

    it 'ignores failed attempts, which have no average likelihood' do
      unit.revision_ai_scores.create!(check_type: 'Pangram 4', avg_ai_likelihood: nil)
      expect(unit.scored_with?('Pangram 4')).to be false

      unit.revision_ai_scores.create!(check_type: 'Pangram 4', avg_ai_likelihood: 0.2)
      expect(unit.scored_with?('Pangram 4')).to be true
      expect(unit.scored_with?('Pangram 3')).to be false
    end
  end

  it 'lists the distinct sample names' do
    described_class.create!(sample_name: 'b', plain_text: text)
    described_class.create!(sample_name: 'a', plain_text: text)
    described_class.create!(sample_name: 'a', plain_text: "#{text} more")

    expect(described_class.sample_names).to eq(%w[a b])
  end
end
