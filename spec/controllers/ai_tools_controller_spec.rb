# frozen_string_literal: true

require 'rails_helper'

describe AiToolsController, type: :request do
  describe '#compare_ai_detectors' do
    let(:admin) { create(:admin) }
    let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
    let(:pangram) { 'Pangram 4.1' }
    let(:model_5) { 'Originality 5.0' }
    let(:model_5_max) { 'Originality 5.0 Max' }
    # Recorded from the live API on 2026-11-17, text fields shortened.
    let(:simplified_originality_response) do
      { 'results' => {
        'properties' => {
          'publicLink' => 'https://app.originality.ai/share/some_link' },
        'ai' => {
          'model' => 'model-5.0',
          'prediction_label' => 'mixed',
          'ai_assisted_percent' => 60,
          'sentences' =>
            [{ 'start_index' => 0, 'end_index' => 230, 'text' => 'first segment of words',
               'ai_score' => 0.6722026056164665 },
             { 'start_index' => 230, 'end_index' => 400, 'text' => 'second segment',
               'ai_score' => 0.18571670712174604 }] },
        'plagiarism' => { 'error' => 'not selected' }
        }
      }
    end
    # Recorded from the live Pangram 4 task endpoint on 2026-09-03 (version updated to 4.1)
    let(:simplified_pangram_response) do
      { 'stage' => 'STAGE_SUCCESS',
        'text' => 'example',
        'version' => '4.1',
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
      allow(AiDetector.for(pangram).client).to receive(:inference)
        .and_return(simplified_pangram_response)
      allow(AiDetector.for(model_5).client).to receive(:inference)
        .and_return(simplified_originality_response)
      allow(AiDetector.for(model_5_max).client).to receive(:inference)
        .and_return(simplified_originality_response.deep_merge(
                      'results' => { 'ai' => { 'model' => 'model-5.0-max' } }
                    ))
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
                                                           pangram.to_sym => '1' }

          expect(RevisionAiScore.count).to eq(1)

        expect(RevisionAiScore.first.check_type).to eq('Pangram 4.1')
        expect(RevisionAiScore.first.check_origin).to eq('ai_tool')
        expect(RevisionAiScore.first.revision_id).to be_nil
        expect(RevisionAiScore.first.wiki_id).to be_nil
        expect(RevisionAiScore.first.url).to be_nil
        expect(RevisionAiScore.first.origin_user_id).to eq(admin.id)
        end
      end

      it 'stores the Pangram 4.1 result including humanizer fields and renders it' do
        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram.to_sym => '1' }

        score = RevisionAiScore.find_by(check_type: 'Pangram 4.1')
        expect(score.check_origin).to eq('ai_tool')
        expect(score.max_ai_likelihood).to be_within(0.0001).of(0.99999)
        expect(score.details['version']).to eq('4.1')
        expect(score.details['windows'].first).to include('is_humanized' => false)
        expect(score.details['windows'].first).not_to have_key('text')

        expect(response.body).to include('Pangram 4.1 Result')
        expect(response.body).to include('Humanizer score')
        expect(response.body).not_to include('Originality 5.0 Result')
      end

      it 'shows the version mismatch when Pangram answers as another version' do
        allow(AiDetector.for(pangram).client).to receive(:inference)
          .and_raise(PangramApi::ModelMismatch, 'expected Pangram 4.1 but got "4.2"')

        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram.to_sym => '1' }

        expect(response.body).to include('Pangram 4.1: expected Pangram 4.1')
        expect(RevisionAiScore.count).to eq(0)
      end

      it 'shows a detector error instead of a result and stores no row for it' do
        allow(AiDetector.for(model_5_max).client).to receive(:inference)
          .and_raise(OriginalityApi::TextTooShort, '3 words; Originality requires 50')

        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram.to_sym => '1',
                                                         model_5_max.to_sym => '1' }

        expect(RevisionAiScore.pluck(:check_type)).to eq(['Pangram 4.1'])
        expect(response.body).to include('Originality requires 50')
        expect(response.body).to include('Pangram 4.1 Result')
      end

      it 'shows a notice when a detector fails at the transport level' do
        allow(AiDetector.for(model_5).client).to receive(:inference)
          .and_raise(Faraday::TimeoutError, 'execution expired')

        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         pangram.to_sym => '1',
                                                         model_5.to_sym => '1' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Originality 5.0: execution expired')
        expect(response.body).to include('Pangram 4.1 Result')
        expect(RevisionAiScore.pluck(:check_type)).to eq(['Pangram 4.1'])
      end

      it 'renders the Originality result with its model, verdict and segment scores' do
        post '/ai_tools/compare_ai_detectors', params: { plain_text:,
                                                         article_or_diff_url: "",
                                                         model_5_max.to_sym => '1' }

        expect(response.body).to include('Originality 5.0 Max Result')
        expect(response.body).to include('Model: model-5.0-max')
        expect(response.body).to include('Prediction: mixed')
        expect(response.body).to include('AI-assisted: 60%')
        expect(response.body).to include('0.6722')
        score = RevisionAiScore.find_by(check_type: model_5_max)
        expect(score.max_ai_likelihood).to be_within(0.0001).of(0.6722)
        expect(score.avg_ai_likelihood).to eq(0.6)
        expect(score.details['results']['ai']['sentences'].first).not_to have_key('text')
      end
    end

    context 'when showing the form' do
      it 'ticks only the Pangram detectors by default' do
        get '/ai_tools'

        page = Nokogiri::HTML(response.body)
        checked = page.css('input[type=checkbox][checked]').map { |box| box['name'] }
        all = page.css('input[type=checkbox]').map { |box| box['name'] }
        expect(checked).to eq([pangram])
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
                                                          pangram.to_sym => '1',
                                                          model_5.to_sym => '1',
                                                          model_5_max.to_sym => '1' }
        end

        expect(RevisionAiScore.count).to eq(3)
        expect(RevisionAiScore.order(:id).pluck(:check_type)).to eq(
          ['Pangram 4.1', 'Originality 5.0', 'Originality 5.0 Max']
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

      it 'calls GetRevisionPlaintext for the edit against its parent' do
        expect(GetRevisionPlaintext).to receive(:new).with(
          936368512,
          enwiki,
          diff_mode: true,
          from_rev: nil
        )

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url }
      end
    end

    context 'when diff next URL' do
      let(:url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=next&oldid=936368512' }

      it 'scores nothing and shows a notice instead of falling back to the latest revision' do
        expect(GetRevisionPlaintext).not_to receive(:new)
        expect(WikiApi::ArticleContent).not_to receive(:new)
        expect(AiDetector.for(pangram).client).not_to receive(:inference)

        post '/ai_tools/compare_ai_detectors', params: { plain_text: "", article_or_diff_url: url,
                                                         pangram.to_sym => '1' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Unsupported URL')
        expect(RevisionAiScore.count).to eq(0)
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
