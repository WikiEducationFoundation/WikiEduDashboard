# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/finding_anchors"

describe ArticleAuditing::FindingAnchors do
  let(:html) do
    <<~HTML
      <div class="mw-parser-output">
      <p><b>Acme</b> is a <a href="/wiki/World">world-class</a> company.<sup class="reference"><a href="#cite_note-1">[1]</a></sup> It makes anvils.</p>
      <div class="mw-heading mw-heading2"><h2 id="History">History</h2><span class="mw-editsection">[edit]</span></div>
      <p>Acme was founded in 1920. It makes anvils.</p>
      <p>Its films include <i>Road Runner</i>.</p>
      <ol class="references"><li id="cite_note-1"><cite>"Acme history". <i>Anvil Weekly</i>.</cite></li></ol>
      </div>
    HTML
  end
  let(:wikitext) do
    "'''Acme''' is a [[World|world-class]] company.<ref>{{cite web |title=Acme history " \
      "|work=Anvil Weekly}}</ref> It makes anvils.\n== History ==\nAcme was founded in 1920. " \
      "It makes anvils.\nIts films include ''Road Runner''."
  end
  let(:anchors) do
    described_class.new(html:, wikitext:, base_url: 'https://en.wikipedia.org', findings:)
  end
  let(:doc) { Nokogiri::HTML.fragment(anchors.html) }

  def finding(id, quote: nil, section: nil, severity: 'should_fix')
    { 'id' => id, 'severity' => severity, 'location' => { 'quote' => quote, 'section' => section } }
  end

  def marked(id)
    doc.css("mark[data-findings~='#{id}']").map(&:text).join
  end

  context 'with quotes of the rendered text' do
    let(:findings) do
      [finding('a', quote: 'is a  World-Class company'),
       finding('b', quote: 'It makes anvils.', section: 'History', severity: 'must_fix')]
    end

    it 'marks the quoted text, across inline elements and ignoring case and spacing' do
      expect(anchors.anchors).to eq('a' => 'text', 'b' => 'text')
      expect(marked('a')).to eq('is a world-class company')
      expect(doc.at_css("mark[data-findings='a']")['class']).to eq('aa-mark aa-mark--should_fix')
    end

    it 'prefers the occurrence in the finding’s section' do
      expect(doc.at_css("mark[data-findings~='b']").ancestors('p').first.text)
        .to start_with('Acme was founded')
    end
  end

  context 'with findings on overlapping text' do
    let(:findings) do
      [finding('a', quote: 'world-class company'),
       finding('b', quote: 'company.', severity: 'must_fix')]
    end

    it 'splits the text so each piece carries every finding on it, colored by the most severe' do
      shared = doc.css('mark').find { |mark| mark['data-findings'] == 'a b' }
      expect(shared.text).to eq('company')
      expect(shared['class']).to include('aa-mark--must_fix')
      expect(marked('a')).to eq('world-class company')
    end
  end

  context 'with quotes of wikitext' do
    let(:findings) do
      [finding('cite', quote: '{{cite web |title=Acme history'),
       finding('italics', quote: "films include ''Road Runner''")]
    end

    it 'marks the citation in the reference list, or the text with its markup stripped' do
      expect(anchors.anchors).to eq('cite' => 'reference', 'italics' => 'text')
      expect(marked('cite')).to eq('Acme history')
      expect(marked('italics')).to eq('films include Road Runner')
    end
  end

  context 'with a quote of only a ref tag' do
    let(:findings) { [finding('ref', quote: '<ref name="smith" />')] }

    it 'does not anchor it to some other citation' do
      expect(anchors.anchors).to eq({})
    end
  end

  context 'with a quote whose rendered text has non-breaking spaces' do
    let(:html) { %(<div class="mw-parser-output"><p>It is 10\u00A0km long.</p></div>) }
    let(:wikitext) { 'It is 10&nbsp;km long.' }
    let(:findings) { [finding('nbsp', quote: 'is 10 km long')] }

    it 'matches them as spaces' do
      expect(anchors.anchors).to eq('nbsp' => 'text')
      expect(marked('nbsp')).to eq("is 10\u00A0km long")
    end
  end

  context 'with findings that have no quote in the article' do
    let(:findings) do
      [finding('section', quote: 'not in the article', section: 'History'),
       finding('lead', section: 'Lead'),
       finding('whole')]
    end

    it 'anchors them to their section heading or the lead, or not at all' do
      expect(anchors.anchors).to eq('section' => 'section', 'lead' => 'section')
      expect(doc.at_css('h2')['data-section-findings']).to eq('section')
      expect(doc.at_css('p')['data-section-findings']).to eq('lead')
    end
  end

  context 'with any findings' do
    let(:findings) { [] }

    it 'points links at the wiki and removes edit links' do
      link = doc.at_css('a[href*="World"]')
      expect(link['href']).to eq('https://en.wikipedia.org/wiki/World')
      expect(link['target']).to eq('_blank')
      expect(doc.at_css('a[href="#cite_note-1"]')['target']).to be_nil
      expect(doc.css('.mw-editsection')).to be_empty
    end
  end
end
