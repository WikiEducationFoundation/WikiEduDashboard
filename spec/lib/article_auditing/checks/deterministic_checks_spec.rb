# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe 'Article Audit deterministic checks' do
  let(:context) do
    instance_double(ArticleAuditing::Context, parsed_wikitext: ArticleAuditing::Wikitext.new(wikitext))
  end
  let(:findings) { described_class.new.run(context).findings }

  describe ArticleAuditing::Checks::ReferenceList do
    context 'with no ref tags' do
      let(:wikitext) { "'''Topic''' is a thing.\n\n==History==\nIt happened." }

      it 'flags missing citations' do
        expect(findings.size).to eq(1)
        expect(findings.first).to include('severity' => 'must_fix', 'category' => 'sourcing',
                                          'check' => 'sourcing.reference_list',
                                          'code' => 'no_citations', 'title' => '',
                                          'explanation' => '', 'details' => nil)
        expect(findings.first['policy_refs']).to include('WP:V')
      end
    end

    context 'with refs but no reference list' do
      let(:wikitext) { "Fact.<ref>Source</ref>\n\n==References==\n" }

      it 'flags the missing list and suggests one' do
        expect(findings.size).to eq(1)
        expect(findings.first['suggestion']).to include('{{Reflist}}')
      end
    end

    context 'with shortened footnotes and a reflist' do
      let(:wikitext) { "Fact.{{sfn|Smith|2001|p=4}}\n\n==References==\n{{reflist}}\n" }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end

    context 'with refs and a reflist' do
      let(:wikitext) { "Fact.<ref>Source</ref>\n\n==References==\n{{reflist|30em}}\n" }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end

    context 'with a reflist only inside a comment' do
      let(:wikitext) { "Fact.<ref>Source</ref>\n<!-- {{Reflist}} -->" }

      it 'still flags the missing list' do
        expect(findings.size).to eq(1)
      end
    end
  end

  describe ArticleAuditing::Checks::ReferencePlacement do
    let(:wikitext) do
      'One fact<ref>A</ref>. Two facts. <ref name="b" /> Three<ref>C</ref>Four. ' \
        'Fine.<ref>D</ref> Done.'
    end

    it 'flags a ref before punctuation, a space before a ref, and no space after a ref' do
      quotes = findings.map { |finding| finding.dig('location', 'quote') }
      expect(findings.size).to eq(3)
      expect(findings.map { |finding| finding['severity'] })
        .to eq(%w[should_fix should_fix suggestion])
      expect(quotes).to all(be_present)
    end

    context 'with correctly placed refs' do
      let(:wikitext) { 'One fact.<ref>A</ref> Two facts,<ref name="b" /> three.<ref>C</ref>' }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end
  end

  describe ArticleAuditing::Checks::LeadSection do
    context 'when the page opens with an Introduction heading' do
      let(:wikitext) { "{{Short description|x}}\n==Introduction==\nText.\n==History==\nMore." }

      it 'reports the heading, not a missing lead as well' do
        expect(findings.size).to eq(1)
        expect(findings.first['severity']).to eq('should_fix')
        expect(findings.first.dig('location', 'section')).to eq('Introduction')
        expect(findings.first.dig('location', 'quote')).to eq('==Introduction==')
      end
    end

    context 'with no lead before an ordinary heading' do
      let(:wikitext) { "{{Short description|x}}\n==History==\nMore." }

      it 'flags the missing lead' do
        expect(findings.map { |finding| finding['severity'] }).to eq(%w[must_fix])
      end
    end

    context 'with a lead' do
      let(:wikitext) { "'''Topic''' is a thing.\n==History==\nMore." }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end
  end

  describe ArticleAuditing::Checks::AppendixSections do
    context 'with misnamed and misordered appendices' do
      let(:wikitext) do
        "Lead.\n==History==\nx\n==External Link==\ny\n==References==\n{{reflist}}\n" \
          "==Legacy==\nz\n"
      end

      it 'suggests the standard name' do
        rename = findings.find { |finding| finding['suggestion'] == '==External links==' }
        expect(rename).to be_present
        expect(rename['severity']).to eq('suggestion')
      end

      it 'flags the order and the content section after the appendices' do
        expect(findings.map { |finding| finding.dig('location', 'section') }).to include('Legacy')
        order = findings.find { |finding| finding['suggestion'] == 'References, External Link' }
        expect(order).to be_present
      end
    end

    context 'with standard appendices in order' do
      let(:wikitext) do
        "Lead.\n==History==\nx\n==See also==\n==References==\n==Further reading==\n" \
          "==External links==\n"
      end

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end
  end

  describe ArticleAuditing::Checks::ExternalLinksInBody do
    let(:wikitext) do
      "Lead with [https://example.com a link].<ref>[https://cited.example.com Cited]</ref>\n" \
        "==History==\nSee {{cite web|url=https://template.example.com}} and " \
        "https://bare.example.org.\n" \
        "==External links==\n* [https://official.example.com Official site]\n"
    end

    it 'flags links in prose but not in refs, templates or External links' do
      quotes = findings.map { |finding| finding.dig('location', 'quote') }
      expect(quotes).to contain_exactly('https://example.com', 'https://bare.example.org.')
      expect(findings.map { |finding| finding.dig('location', 'section') }).to eq([nil, 'History'])
    end
  end
end
