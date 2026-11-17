# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/wiki_context"

describe ArticleAuditing::WikiContext do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:api) { instance_double(WikiApi) }

  def wiki_context(title, namespace)
    described_class.new(wiki:, title:, namespace:)
  end

  def response(data)
    instance_double(MediawikiApi::Response, data:)
  end

  before { allow(WikiApi).to receive(:new).and_return(api) }

  describe '#target_title' do
    it 'is the title in mainspace, without Draft: in draft space, and a user subpage name' do
      expect(wiki_context('Selfie', 0).target_title).to eq('Selfie')
      expect(wiki_context('Draft:Selfie', 118).target_title).to eq('Selfie')
      expect(wiki_context('User:Ex/Marie Curie', 2).target_title).to eq('Marie Curie')
      expect(wiki_context('User:Ex/Draft:Marie Curie', 2).target_title).to eq('Marie Curie')
    end

    it 'is nil for generic sandboxes and plain user pages' do
      expect(wiki_context('User:Ex/sandbox', 2).target_title).to be_nil
      expect(wiki_context('User:Ex/Sandbox2', 2).target_title).to be_nil
      expect(wiki_context('User:Ex', 2).target_title).to be_nil
      expect(wiki_context('Wikipedia:Sandbox', 4).target_title).to be_nil
    end
  end

  describe '#target_page' do
    it 'summarizes an existing target and caches the lookup' do
      allow(api).to receive(:query).and_return(response('pages' => { '7' => {
        'pageid' => 7, 'title' => 'Marie Curie', 'length' => 900,
        'pageprops' => { 'wikibase_item' => 'Q7186' },
        'categories' => [{ 'title' => 'Category:Physicists' }],
        'templates' => [{ 'title' => 'Template:Use British English' }],
        'pageassessments' => { 'Biography' => { 'class' => 'FA' } }
      } }))
      context = wiki_context('User:Ex/Marie Curie', 2)
      expect(context.target_page).to include(exists: true, wikibase_item: 'Q7186',
                                             assessment_class: 'FA',
                                             categories: ['Category:Physicists'])
      expect(context.target_exists?).to be(true)
      context.target_page
      expect(api).to have_received(:query).once
    end

    it 'reports a missing target' do
      allow(api).to receive(:query)
        .and_return(response('pages' => { '-1' => { 'title' => 'New Topic', 'missing' => '' } }))
      expect(wiki_context('Draft:New Topic', 118).target_exists?).to be(false)
    end
  end

  describe '#existing_titles' do
    it 'follows normalization and redirects, and skips missing and disambiguation pages' do
      allow(api).to receive(:query).and_return(response(
        'normalized' => [{ 'from' => 'nature (journal)', 'to' => 'Nature (journal)' }],
        'redirects' => [{ 'from' => 'Curie', 'to' => 'Marie Curie' }],
        'pages' => {
          '1' => { 'title' => 'Nature (journal)', 'description' => 'Scientific journal' },
          '2' => { 'title' => 'Marie Curie', 'description' => 'Physicist (1867–1934)' },
          '3' => { 'title' => 'Mercury', 'pageprops' => { 'disambiguation' => '' } },
          '-1' => { 'title' => 'Nope', 'missing' => '' }
        }
      ))
      found = wiki_context('Selfie', 0)
              .existing_titles(['nature (journal)', 'Curie', 'Mercury', 'Nope'])
      expect(found).to eq(
        'nature (journal)' => { title: 'Nature (journal)', description: 'Scientific journal' },
        'Curie' => { title: 'Marie Curie', description: 'Physicist (1867–1934)' }
      )
    end
  end

  describe '#unlinked_mentions' do
    it 'searches for mentions that do not link the target, excluding the target itself' do
      results = [{ 'title' => 'Selfie', 'snippet' => 'x' },
                 { 'title' => 'Smartphone', 'snippet' => 'a <span>selfie</span>' }]
      allow(api).to receive(:query).and_return(response('search' => results))
      expect(wiki_context('Selfie', 0).unlinked_mentions)
        .to eq([{ title: 'Smartphone', snippet: 'a selfie' }])
      expect(api).to have_received(:query)
        .with(hash_including(list: 'search', srsearch: '"Selfie" -linksto:"Selfie"'))
    end
  end

  describe '#navboxes_linking_target' do
    it 'keeps only linking templates that transclude Navbox' do
      allow(api).to receive(:query) do |params|
        if params[:prop] == 'linkshere'
          response('pages' => { '1' => { 'linkshere' => [{ 'title' => 'Template:Physics' },
                                                          { 'title' => 'Template:Cite web' }] } })
        else
          response('pages' => { '1' => { 'title' => 'Template:Physics',
                                          'templates' => [{ 'title' => 'Template:Navbox' }] },
                                '2' => { 'title' => 'Template:Cite web' } })
        end
      end
      expect(wiki_context('Selfie', 0).navboxes_linking_target).to eq(['Template:Physics'])
    end
  end
end
