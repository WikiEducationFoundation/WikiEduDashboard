# frozen_string_literal: true

require 'rails_helper'

describe AboutThisSiteController, type: :request do
  describe '#private_information' do
    it 'renders privacy-related info' do
      get '/private_information'
      expect(response.status).to eq(200)
      expect(response.body).to include('Private Information')
    end
  end

  describe '#accessibility' do
    it 'renders the VPAT from the Markdown source, with tables' do
      get '/accessibility'
      expect(response.status).to eq(200)
      expect(response.body).to include('Voluntary Product Accessibility Template')
      expect(response.body).to include('<table>')
      expect(response.body).to include('Success Criteria, Level AA')
    end

    it 'is not served on the P&E Dashboard deployment' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/accessibility'
      expect(response.status).to eq(404)
    end
  end

  describe '#canvas_integration_guide' do
    it 'renders the Canvas integration guide from the Markdown source' do
      get '/lti/guide'
      expect(response.status).to eq(200)
      expect(response.body).to include('Adding the Wiki Education Dashboard to your Canvas')
    end

    it 'is not served on the P&E Dashboard deployment' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/lti/guide'
      expect(response.status).to eq(404)
    end
  end

  describe '#canvas_instructor_guide' do
    it 'renders the instructor install page from the Markdown source' do
      get '/lti/guide/instructors'
      expect(response.status).to eq(200)
      expect(response.body).to include('Add the Wiki Education Dashboard to your Canvas course')
    end

    it 'is not served on the P&E Dashboard deployment' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/lti/guide/instructors'
      expect(response.status).to eq(404)
    end
  end

  describe '#hecvat' do
    it 'renders the HECVAT from the Markdown source' do
      get '/hecvat'
      expect(response.status).to eq(200)
      expect(response.body).to include('HECVAT 4.1.6 (Core)')
    end

    it 'is not served on the P&E Dashboard deployment' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/hecvat'
      expect(response.status).to eq(404)
    end
  end

  describe '#metrics' do
    it 'renders the glossary from docs/metrics, with the AI disclosure and code links' do
      get '/metrics'
      expect(response.status).to eq(200)
      expect(response.body).to include('drafted by Claude Code')
      expect(response.body).to match(/id=["']words_added["']/)
      expect(response.body).to include('/blob/master/lib/word_count.rb#L')
    end

    context 'with an admin-only entry' do
      let(:dir) { Dir.mktmpdir }
      let(:metric) do
        { 'name' => 'Secret stat', 'summary' => 'Hidden.', 'explanation' => 'Admins only.',
          'audience' => 'admin',
          'implementations' => [{ 'ruby' => 'WordCount.from_characters',
                                  'path' => 'lib/word_count.rb' },
                                { 'ruby' => 'WordCount.no_such_method',
                                  'path' => 'lib/word_count.rb' }] }
      end

      before do
        File.write(File.join(dir, 'admin.yml'),
                   { 'metrics' => { 'secret_stat' => metric } }.to_yaml)
        File.write(File.join(dir, 'layout.yml'),
                   { 'sections' => { 'admin_stats' => { 'title' => 'Admin stats',
                                                         'metrics' => ['secret_stat'] } } }.to_yaml)
        allow(MetricsGlossary).to receive(:current).and_return(MetricsGlossary.new(dir))
      end

      after { FileUtils.remove_entry(dir) }

      it 'leaves it out for non-admins' do
        get '/metrics'
        expect(response.body).not_to include('Secret stat')
      end

      it 'shows it to admins' do
        login_as create(:admin)
        get '/metrics'
        expect(response.body).to include('Secret stat')
        expect(response.body).to include('Admin only')
      end

      it 'shows a code pointer that no longer resolves as plain text' do
        login_as create(:admin)
        get '/metrics'
        expect(response.status).to eq(200)
        expect(response.body).to include('<code>WordCount.no_such_method</code>')
      end
    end
  end
end
