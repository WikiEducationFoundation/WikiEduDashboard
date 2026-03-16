# frozen_string_literal: true

require 'rails_helper'

describe AiToolsController, type: :request do
  describe '#compare_ai_detectors' do
    let(:admin) { create(:admin) }
    let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    context 'when plain text' do
      let(:plain_text) { 'Example text...' }

      it 'does not call GetRevisionPlaintext' do
        expect(GetRevisionPlaintext).not_to receive(:new)

        post '/ai_tools/compare_ai_detectors', params: { plain_text:, article_or_diff_url: "" }
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
    end

    context 'when article URL' do
      let(:url) { 'https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association' }
      let(:content) { { 'pages' => { '45' => { 'revisions' => [ { 'revid' => 45 } ] } } } }
      let(:response) { instance_double(MediawikiApi::Response, data: content) }
      it 'calls GetRevisionPlaintext with diff_mode true and rev_id set' do
        # response.data['pages'].values.first['revisions'].first['revid']
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