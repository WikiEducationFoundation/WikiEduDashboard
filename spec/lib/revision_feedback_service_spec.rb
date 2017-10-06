# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/revision_feedback_service"

describe RevisionFeedbackService do
  describe '#feedback' do
    let(:subject) { described_class.new(features).feedback }

    context 'when the revision has no feature data' do
      let(:features) { nil }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'When features can prompt feeback' do
      let(:features) do
        { 'feature.enwiki.revision.cite_templates' => 6,
          'feature.wikitext.revision.ref_tags' => 0,
          'feature.wikitext.revision.content_chars' => 9001,
          'feature.wikitext.revision.headings_by_level(2)' => 0,
          'feature.wikitext.revision.headings_by_level(3)' => 0 }
      end

      it 'returns an array of relevant feedback' do
        expect(subject.length).to eq(2)
      end
    end

    context 'when the feature data does not prompt feedback' do
      let(:features) do
        { 'feature.enwiki.revision.cite_templates' => 6,
          'feature.wikitext.revision.ref_tags' => 10,
          'feature.wikitext.revision.content_chars' => 9001,
          'feature.wikitext.revision.headings_by_level(2)' => 4,
          'feature.wikitext.revision.headings_by_level(3)' => 1 }
      end

      it 'returns an empty array' do
        expect(subject.length).to eq(0)
      end
    end
  end
end
