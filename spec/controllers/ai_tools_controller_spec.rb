# frozen_string_literal: true

require 'rails_helper'

describe AiToolsController, type: :request do
  describe '#compare_ai_detectors' do
    let(:admin) { create(:admin) }
    let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
    let(:pangram_v3) { 'Pangram 3' }
    let(:turbo) { 'Originality Turbo' }
    let(:academic) { 'Originality Academic' }
    let(:lite) { 'Originality Lite 1.0.0' }
    let(:lite_beta) { 'Originality Lite 1.0.2' }
    let(:simplified_originality_response) do
      { 'results' => {
        'properties' => {
          'publicLink' => 'https://app.originality.ai/share/some_link' },
        'ai' => {
          'aiModel' => 'academic',
          'classification' => { 'AI' => 1, 'Original' => 0 },
          'confidence' =>  { 'AI' => 1, 'Original' => 0 },
          'blocks' =>
            [{ 'result' => { 'fake' => 0.6722026056164665,
                             'real' => 0.3277973943835335,
                             'status' => 'success' } },
             { 'result' => { 'fake' => 0.18571670712174604,
                             'real' => 0.814283292878254,
                             'status' => 'success' } }] },
        'plagiarism' => { 'error' => 'not selected' }
        }
      }
    end
    let(:simplified_pangram_response) do
      { 'text' => 'example',
        'version' => '3.0',
        'headline' => 'Fully AI Generated',
        'prediction' => 'We are confident that this document is fully AI-generated',
        'prediction_short' => 'AI',
        'fraction_ai' => 1.0,
        'fraction_ai_assisted' => 0.0,
        'fraction_human' => 0.0,
        'num_ai_segments' => 3,
        'num_ai_assisted_segments' => 0,
        'num_human_segments' => 0,
        'windows' =>
          [{ 'text' => 'first window',
            'label' => 'AI-Generated',
            'ai_assistance_score' => 1.0,
            'confidence' => 'High',
            'start_index' => 0,
            'end_index' => 2281,
            'word_count' => 359,
            'token_length' => 483 },
          { 'text' => 'second window',
            'label' => 'AI-Generated',
            'ai_assistance_score' => 0.9982278487261604,
            'confidence' => 'High',
            'start_index' => 2281,
            'end_index' => 4737,
            'word_count' => 358,
            'token_length' => 476 },
          { 'text' => 'third window',
            'label' => 'AI-Generated',
            'ai_assistance_score' => 0.9959831237792969,
            'confidence' => 'High',
            'start_index' => 4737,
            'end_index' => 5202,
            'word_count' => 72,
            'token_length' => 94 }],
        'dashboard_link' => 'https://www.pangram.com/history/7980768b-0b15-4d42-ad62-30ba8cf0e92f'
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      allow_any_instance_of(PangramApi).to receive(:inference)
                                           .and_return(simplified_pangram_response)
      allow_any_instance_of(OriginalityApi).to receive(:inference)
                                           .and_return(simplified_originality_response)
    end

    context 'when plain text' do
      let(:plain_text) { 'Example text...' }

      it 'does not call GetRevisionPlaintext' do
        expect(GetRevisionPlaintext).not_to receive(:new)

        post '/ai_tools/compare_ai_detectors', params: { plain_text:, article_or_diff_url: "" }
      end

      it 'does create revision_ai_score rows' do
        VCR.use_cassette 'pangram' do
          post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                           article_or_diff_url: "",
                                                           pangram_v3.to_sym => '1' }

          expect(RevisionAiScore.count).to eq(1)

        expect(RevisionAiScore.first.check_type).to eq('Pangram 3')
        expect(RevisionAiScore.first.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.first.revision_id).to be_nil
        expect(RevisionAiScore.first.wiki_id).to be_nil
        expect(RevisionAiScore.first.url).to be_nil
        expect(RevisionAiScore.first.origin_user_id).to eq(admin.id)
        end
      end
    end

    context 'when revision title URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?title=List_of_the_busiest_airports_in_Malaysia&oldid=1276659876' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          1276659876,
          enwiki,
          diff_mode: false,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end

      it 'does create revision_ai_score rows' do
        VCR.use_cassette 'pangram' do
          post '/ai_tools/compare_ai_detectors', params: { plain_text: "",
                                                          article_or_diff_url: url,
                                                          pangram_v3.to_sym => '1',
                                                          turbo.to_sym => '1',
                                                          academic.to_sym => '1',
                                                          lite.to_sym => '1',
                                                          lite_beta.to_sym => '1' }
        end

        expect(RevisionAiScore.count).to eq(5)

        expect(RevisionAiScore.first.check_type).to eq('Pangram 3')
        expect(RevisionAiScore.first.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.first.revision_id).to eq(1276659876)
        expect(RevisionAiScore.first.wiki_id).to eq(enwiki.id)
        expect(RevisionAiScore.first.url).to eq(url)
        expect(RevisionAiScore.first.origin_user_id).to eq(admin.id)

        expect(RevisionAiScore.second.check_type).to eq('Originality Turbo')
        expect(RevisionAiScore.second.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.second.revision_id).to eq(1276659876)
        expect(RevisionAiScore.second.wiki_id).to eq(enwiki.id)
        expect(RevisionAiScore.second.url).to eq(url)
        expect(RevisionAiScore.second.origin_user_id).to eq(admin.id)

        expect(RevisionAiScore.third.check_type).to eq('Originality Academic')
        expect(RevisionAiScore.third.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.third.revision_id).to eq(1276659876)
        expect(RevisionAiScore.third.wiki_id).to eq(enwiki.id)
        expect(RevisionAiScore.third.url).to eq(url)
        expect(RevisionAiScore.third.origin_user_id).to eq(admin.id)

        expect(RevisionAiScore.fourth.check_type).to eq('Originality Lite 1.0.0')
        expect(RevisionAiScore.fourth.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.fourth.revision_id).to eq(1276659876)
        expect(RevisionAiScore.fourth.wiki_id).to eq(enwiki.id)
        expect(RevisionAiScore.fourth.url).to eq(url)
        expect(RevisionAiScore.fourth.origin_user_id).to eq(admin.id)

        expect(RevisionAiScore.last.check_type).to eq('Originality Lite 1.0.2')
        expect(RevisionAiScore.last.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.last.revision_id).to eq(1276659876)
        expect(RevisionAiScore.last.wiki_id).to eq(enwiki.id)
        expect(RevisionAiScore.last.url).to eq(url)
        expect(RevisionAiScore.last.origin_user_id).to eq(admin.id)
      end
    end

    context 'when article URL' do
      let(:url) { 'https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association' }
      let(:content) { { 'pages' => { '45' => { 'revisions' => [ { 'revid' => 45 } ] } } } }
      let(:response) { instance_double(MediawikiApi::Response, data: content) }
      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        allow_any_instance_of(WikiApi).to receive(:query).and_return(response)
        expect(GetRevisionPlaintext).to receive(:new).with(
          45,
          enwiki,
          diff_mode: false,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when revision URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?oldid=1315039613' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          1315039613,
          enwiki,
          diff_mode: false,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when diff prev URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          936368512,
          enwiki,
          diff_mode: true,
          from_rev: 0
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when diff range URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=1178859026&oldid=711811679' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          1178859026,
          enwiki,
          diff_mode: true,
          from_rev: 711811679
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when diff title URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?title=List_of_hystricids&diff=1315039613' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          1315039613,
          enwiki,
          diff_mode: true,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when diff URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?diff=1315039613' }

      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          1315039613,
          enwiki,
          diff_mode: true,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end
  end
end
