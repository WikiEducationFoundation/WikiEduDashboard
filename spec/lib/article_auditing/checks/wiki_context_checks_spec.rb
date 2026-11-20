# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe 'Article Audit wiki-context checks' do
  let(:wikitext) { "'''Topic''' is a thing." }
  let(:mainspace) { false }
  let(:new_article) { false }
  let(:target_page) { { exists: true, title: 'Topic', templates: [], wikibase_item: 'Q1' } }
  let(:wiki_context) do
    instance_double(ArticleAuditing::WikiContext, target_title: 'Topic', target_page:,
                                                  target_exists?: target_page[:exists])
  end
  let(:context) do
    instance_double(ArticleAuditing::Context, parsed_wikitext: ArticleAuditing::Wikitext.new(wikitext),
                                              wikitext:, wiki_context:, mainspace?: mainspace,
                                              new_article?: new_article)
  end
  let(:output) { described_class.new.run(context) }
  let(:findings) { output.findings }

  describe ArticleAuditing::Checks::WikidataItem do
    context 'when the target exists without an item' do
      let(:target_page) { { exists: true, title: 'Topic', wikibase_item: nil } }

      it 'suggests creating or linking one' do
        expect(findings.map { |f| f['severity'] }).to eq(['suggestion'])
      end
    end

    context 'when the target exists with an item' do
      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end

    context 'when the target does not exist yet' do
      let(:target_page) { { exists: false, title: 'Topic' } }

      before do
        candidates = [
          { id: 'Q5', label: 'Topic', description: 'a thing', enwiki: nil },
          { id: 'Q6', label: 'Topic', description: 'other', enwiki: 'Topic (film)' }
        ]
        allow(wiki_context).to receive(:wikidata_candidates).with('Topic').and_return(candidates)
      end

      it 'lists candidate items and notes one already linked to an article' do
        expect(findings.map { |f| f['severity'] }).to contain_exactly('info', 'info')
        expect(findings.first['details']).to eq('id' => 'Q6', 'article' => 'Topic (film)')
        expect(output.artifacts['wikidata_candidates'].map { |c| c['id'] }).to eq(%w[Q5 Q6])
      end
    end
  end

  describe ArticleAuditing::Checks::Navboxes do
    let(:wikitext) { "Text.\n{{Physics topics}}\n" }
    let(:target_page) { { exists: true, title: 'Topic', templates: ['Template:Chemistry'] } }

    before do
      allow(wiki_context).to receive(:navboxes_linking_target)
        .and_return(['Template:Physics topics', 'Template:Chemistry', 'Template:Biology'])
    end

    it 'suggests navboxes not already on the page or the target article' do
      expect(findings.map { |f| f['suggestion'] }).to eq(['{{Biology}}'])
    end
  end

  describe ArticleAuditing::Checks::AuthorLinks do
    let(:wikitext) do
      'A.<ref>{{cite journal |last1=Curie |first1=Marie |journal=Nature |title=X}}</ref> ' \
        'B.<ref>{{cite book |author=Jane Unknown |author-link=Jane Unknown ' \
        '|publisher=[[Penguin]]}}</ref>'
    end

    before do
      allow(wiki_context).to receive(:existing_titles).and_return(
        'Marie Curie' => { title: 'Marie Curie', description: 'Physicist (1867–1934)' },
        'Nature (journal)' => { title: 'Nature (journal)', description: 'Scientific journal' },
        'Nature' => { title: 'Nature', description: 'Natural, physical, or material world' }
      )
    end

    it 'suggests author-link and a journal link, preferring the typed title' do
      expect(findings.map { |f| f['suggestion'] })
        .to contain_exactly('|author-link1=Marie Curie', '|journal=[[Nature (journal)|Nature]]')
    end

    it 'skips authors already linked and works already wikilinked' do
      expect(wiki_context).to receive(:existing_titles) do |titles|
        expect(titles).not_to include('Jane Unknown', 'Penguin')
        {}
      end
      findings
    end
  end

  describe ArticleAuditing::Checks::IncomingLinks do
    before do
      mentions = [{ title: 'Other', snippet: 'topic' }]
      allow(wiki_context).to receive_messages(incoming_link_count: links,
                                              unlinked_mentions: mentions)
    end

    context 'with an orphaned article' do
      let(:links) { 0 }

      it 'flags it and suggests articles that mention it' do
        expect(findings.map { |f| f['severity'] }).to eq(%w[should_fix suggestion])
        expect(output.artifacts['unlinked_mentions'])
          .to eq([{ 'title' => 'Other', 'snippet' => 'topic' }])
      end
    end

    context 'with a well-linked existing article' do
      let(:links) { 40 }

      it 'reports nothing but keeps the mentions as an artifact' do
        expect(findings).to be_empty
        expect(output.artifacts['unlinked_mentions'].size).to eq(1)
      end
    end
  end

  describe ArticleAuditing::Checks::EnglishVariety do
    let(:wikitext) { "The colour of the [[Kennedy Center]] behavior and the center.\n" }
    let(:target_page) do
      { exists: true, title: 'Topic', templates: ['Template:Use American English'] }
    end

    before { allow(wiki_context).to receive(:talk_page).and_return(nil) }

    it 'flags lowercase spellings from another variety than the declared one' do
      expect(findings.map { |f| f.dig('location', 'quote') }).to eq(['colour'])
    end

    context 'with Philippine English declared' do
      let(:target_page) do
        { exists: true, title: 'Topic', templates: ['Template:Use Philippine English'] }
      end

      it 'checks for American spelling' do
        expect(findings.map { |f| f.dig('location', 'quote') }).to eq(['colour'])
      end
    end

    context 'with Canadian English declared' do
      let(:target_page) do
        { exists: true, title: 'Topic', templates: ['Template:Use Canadian English'] }
      end

      it 'does not check spelling' do
        expect(findings).to be_empty
        expect(output.usage['established']).to eq(:canadian)
      end
    end

    context 'with no declared variety' do
      let(:target_page) { { exists: true, title: 'Topic', templates: [] } }

      before do
        allow(wiki_context).to receive(:target_first_revision_text)
          .and_return('The colour, the centre, the behaviour and the favour.')
      end

      it 'uses the first revision’s spelling' do
        expect(findings.map { |f| f.dig('location', 'quote') })
          .to contain_exactly('behavior', 'center')
        expect(output.usage['established']).to eq(:british)
      end
    end
  end

  describe ArticleAuditing::Checks::Speciesbox do
    let(:wikitext) { "{{Taxobox\n| binomial = ''Felis catus''\n}}\nText." }

    it 'recommends Speciesbox when the taxonomy template exists' do
      allow(wiki_context).to receive(:existing_titles).with(['Template:Taxonomy/Felis'])
                                                      .and_return('Template:Taxonomy/Felis' => {})
      expect(findings.first['suggestion']).to include('genus = Felis', 'species = catus')
    end

    it 'says the taxonomy template is needed when it does not exist' do
      allow(wiki_context).to receive(:existing_titles).and_return({})
      expect(findings.first['severity']).to eq('info')
      expect(findings.first['suggestion']).to be_nil
    end
  end

  describe ArticleAuditing::Checks::TargetStatus do
    let(:target_page) { { exists: true, title: 'Topic', assessment_class: 'GA' } }

    before do
      allow(wiki_context).to receive(:talk_page).and_return(
        templates: ['Template:Contentious topics/talk notice'], recent_edits: 25
      )
    end

    it 'notes a Good article target, a contentious topic and an active talk page' do
      expect(findings.size).to eq(3)
      expect(findings.map { |f| f['category'] }.uniq).to eq(['flags'])
    end

    context 'when the audited page is the article itself' do
      let(:mainspace) { true }

      it 'leaves the quality rating to the page-status check' do
        expect(findings.size).to eq(2)
      end
    end
  end
end
