# frozen_string_literal: true

require 'rails_helper'

describe AiToolsController, type: :request do
  describe '#compare_ai_detectors' do
    let(:admin) { create(:admin) }
    let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
    let(:pangram_v3) { 'Pangram 3' }
    let(:pangram_v4) { 'Pangram 4' }
    let(:turbo) { 'Originality Turbo' }
    let(:academic) { 'Originality Academic' }
    let(:lite_102) { 'Originality Lite 1.0.2' }
    let(:allowance_15) { 'Originality AI Allowance 15' }
    let(:allowance_40) { 'Originality AI Allowance 40' }
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
    # Recorded from the live Pangram 4 task endpoint on 2026-09-03
    let(:simplified_pangram_v4_response) do
      { 'stage' => 'STAGE_SUCCESS',
        'text' => 'example',
        'version' => '4.0',
        'prediction' => 'We believe that this entire text is AI.',
        'prediction_short' => 'AI',
        'fraction_ai' => 1.0,
        'fraction_ai_assisted' => 0.0,
        'fraction_human' => 0.0,
        'headline' => 'AI Generated',
        'num_ai_segments' => 1,
        'num_ai_assisted_segments' => 0,
        'num_human_segments' => 0,
        'windows' =>
          [{ 'text' => 'only window',
             'label' => 'AI-Generated',
             'ai_assistance_score' => 0.9999960660934448,
             'confidence' => 'High',
             'start_index' => 0,
             'end_index' => 2281,
             'word_count' => 313,
             'token_length' => 392,
             'is_humanized' => false,
             'humanizer_score' => 0.004439877346158028 }],
        'dashboard_link' => 'https://www.pangram.com/history/8b8e9ea2-3b4c-4773-afe5-93d8dae80736'
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      allow(AiDetector.for(pangram_v3).client).to receive(:inference)
        .and_return(simplified_pangram_response)
      allow(AiDetector.for(pangram_v4).client).to receive(:inference)
        .and_return(simplified_pangram_v4_response)
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

      it 'stores the Pangram 4 result including humanizer fields and renders it' do
        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram_v4.to_sym => '1' }

        score = RevisionAiScore.find_by(check_type: 'Pangram 4')
        expect(score.check_origin).to eq('ai_tool')
        expect(score.max_ai_likelihood).to be_within(0.0001).of(0.99999)
        expect(score.details['version']).to eq('4.0')
        expect(score.details['windows'].first).to include('is_humanized' => false)
        expect(score.details['windows'].first).not_to have_key('text')

        expect(response.body).to include('Pangram 4 Result')
        expect(response.body).to include('Humanizer score')
        expect(response.body).not_to include('Pangram 3 Result')
      end

      it 'shows a detector error instead of a result and stores no row for it' do
        allow(AiDetector.for(allowance_40).client).to receive(:inference)
          .and_raise(OriginalityApi::TextTooShort, '3 words; Originality requires 50')

        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram_v4.to_sym => '1',
                                                         allowance_40.to_sym => '1' }

        expect(RevisionAiScore.pluck(:check_type)).to eq(['Pangram 4'])
        expect(response.body).to include('Originality requires 50')
        expect(response.body).to include('Pangram 4 Result')
      end

      it 'renders the Originality result with its model and block scores' do
        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         academic.to_sym => '1' }

        expect(response.body).to include('Originality Academic Result')
        expect(response.body).to include('Model: academic')
        expect(response.body).to include('0.6722')
        score = RevisionAiScore.find_by(check_type: academic)
        expect(score.max_ai_likelihood).to be_within(0.0001).of(0.6722)
        expect(score.avg_ai_likelihood).to eq(1)
      end
    end

    context 'when showing the form' do
      it 'ticks only the Pangram detectors by default' do
        get '/ai_tools'

        page = Nokogiri::HTML(response.body)
        checked = page.css('input[type=checkbox][checked]').map { |box| box['name'] }
        all = page.css('input[type=checkbox]').map { |box| box['name'] }
        expect(checked).to eq([pangram_v3, pangram_v4])
        expect(all).to eq(AiDetector.keys)
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
                                                          pangram_v4.to_sym => '1',
                                                          lite_102.to_sym => '1',
                                                          turbo.to_sym => '1',
                                                          academic.to_sym => '1',
                                                          allowance_15.to_sym => '1',
                                                          allowance_40.to_sym => '1' }
        end

        expect(RevisionAiScore.count).to eq(7)
        expect(RevisionAiScore.order(:id).pluck(:check_type)).to eq(
          ['Pangram 3', 'Pangram 4', 'Originality Lite 1.0.2', 'Originality Turbo',
           'Originality Academic', 'Originality AI Allowance 15', 'Originality AI Allowance 40']
        )

        RevisionAiScore.find_each do |score|
          expect(score.check_origin).to eq('ai_tool')
          expect(score.revision_id).to eq(1276659876)
          expect(score.wiki_id).to eq(enwiki.id)
          expect(score.url).to eq(url)
          expect(score.origin_user_id).to eq(admin.id)
        end
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
