# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe 'Article Audit deterministic checks, part 2' do
  let(:mainspace) { false }
  let(:plaintext) { '' }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:context) do
    instance_double(ArticleAuditing::Context, parsed_wikitext: ArticleAuditing::Wikitext.new(wikitext),
                                              mainspace?: mainspace, plaintext:, wiki:)
  end
  let(:findings) { described_class.new.run(context).findings }
  let(:quotes) { findings.map { |finding| finding.dig('location', 'quote') } }

  describe ArticleAuditing::Checks::Emphasis do
    let(:wikitext) do
      "'''Acme''' is a company.\n==History==\nIt was '''very''' big and <u>famous</u>.\n" \
        "; '''Term''' : definition\n===Lead===\n'''Acme''' in a draft lead.\n"
    end

    it 'flags bold and underline in the body but not leads or definition terms' do
      expect(quotes).to contain_exactly("'''very'''", '<u>famous</u>')
      expect(findings.map { |f| f.dig('location', 'section') }.uniq).to eq(['History'])
      expect(findings.map { |f| f['severity'] }.uniq).to eq(['suggestion'])
    end
  end

  describe ArticleAuditing::Checks::InappropriateExternalLinks do
    let(:wikitext) do
      "Lead.<ref>https://facebook.com/cited</ref>\n==External links==\n" \
        "* [https://acme.example.com Official]\n" \
        "* [https://www.facebook.com/acme Facebook]\n* https://acme.blogspot.com/post\n"
    end

    it 'flags social and user-generated sites in External links only' do
      expect(quotes).to contain_exactly('https://www.facebook.com/acme',
                                        'https://acme.blogspot.com/post')
    end
  end

  describe ArticleAuditing::Checks::DuplicateLinks do
    let(:wikitext) do
      "[[Paris]] lead.\n==History==\n[[Paris]] once, [[paris|again]], and [[France]].\n" \
        "{{Infobox|city=[[Paris]]}}\n==Later==\n" \
        "[[File:X.jpg]] [[File:X.jpg]] [[Paris#Old|old Paris]] [[France]]\n" \
        "==See also==\n* [[France]]\n* [[Paris]]\n"
    end

    it 'flags repeated body links, most repeated first, ignoring the lead, templates, ' \
       'files and See also' do
      expect(findings.size).to eq(2)
      expect(findings.first['details']).to eq('target' => 'Paris', 'count' => 3)
      expect(findings.last['details']).to eq('target' => 'France', 'count' => 2)
      expect(quotes.first).to eq('[[paris|again]]')
    end
  end

  describe ArticleAuditing::Checks::DateFormat do
    context 'with a declared format' do
      let(:wikitext) { "{{Use dmy dates|date=May 2024}}\nBorn 5 March 1990, died June 2, 2020." }

      it 'flags dates in the other format' do
        expect(quotes).to eq(['June 2, 2020'])
      end
    end

    context 'with a declared format and other-format dates in citations' do
      let(:wikitext) do
        "{{Use dmy dates|date=May 2024}}\nBorn 5 March 1990.<ref>{{cite web |title=T " \
          "|date=June 2, 2020 |access-date=July 3, 2021}}</ref>"
      end

      it 'ignores the citation dates' do
        expect(findings).to be_empty
      end
    end

    context 'with no declared format and mixed dates' do
      let(:wikitext) { 'On 5 March 1990, 6 March 1990 and June 2, 2020.' }

      it 'notes the mix once, quoting the minority format' do
        expect(findings.size).to eq(1)
        expect(quotes).to eq(['June 2, 2020'])
      end
    end

    context 'with consistent dates' do
      let(:wikitext) { 'On 5 March 1990 and 2 June 2020.' }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end
  end

  describe ArticleAuditing::Checks::PageNumbers do
    let(:wikitext) do
      'A.<ref>{{cite book |title=No Pages |isbn=1}}</ref> ' \
        'B.<ref>{{cite book |title=Has Pages |page=4}}</ref> ' \
        'C.<ref name="r">{{cite book |title=Uses Rp}}</ref>{{rp|12}} ' \
        'D.<ref>{{cite web |title=Web}}</ref> E.<ref>{{citation |title=Journal |journal=J}}</ref>'
    end

    it 'flags book citations with no page numbers or {{rp}}' do
      expect(findings.size).to eq(1)
      expect(quotes.first).to include('No Pages')
    end

    context 'with shortened footnotes' do
      let(:wikitext) do
        "A.{{sfn|Smith|2001|p=4}} B.<ref>{{cite book |title=In Ref}}</ref>\n" \
          "==Sources==\n* {{cite book |last=Smith |title=Bibliography Entry |year=2001}}\n"
      end

      it 'leaves the bibliography entries alone' do
        expect(quotes.size).to eq(1)
        expect(quotes.first).to include('In Ref')
      end
    end
  end

  describe ArticleAuditing::Checks::DraftingLeftovers do
    let(:wikitext) do
      "{{Dashboard.wikiedu.org sandbox}}\n==Article Draft (Toward bottom of page)==\n" \
        "===Article body===\nText.\n===References [TEMP]===\n{{reflist}}\n"
    end

    it 'flags sandbox templates, draft headings and markers' do
      expect(quotes).to include('{{Dashboard.wikiedu.org sandbox}}',
                                '==Article Draft (Toward bottom of page)==',
                                '===Article body===', '===References [TEMP]===')
      expect(findings.map { |f| f['severity'] }.uniq).to eq(['should_fix'])
    end

    context 'when the page is in mainspace' do
      let(:mainspace) { true }

      it 'makes them must-fix' do
        expect(findings.map { |f| f['severity'] }.uniq).to eq(['must_fix'])
      end
    end
  end

  describe ArticleAuditing::Checks::PageFlags do
    let(:wikitext) { "{{Good article}}\n{{Recent death|date=May 2026}}\nText." }

    it 'notes the page status as info' do
      expect(findings.map { |f| f['severity'] }).to eq(%w[info info])
      expect(findings.map { |f| f['category'] }.uniq).to eq(['flags'])
      expect(quotes).to contain_exactly('{{Good article}}', '{{Recent death|date=May 2026}}')
    end
  end

  describe ArticleAuditing::Checks::SentenceSpacing do
    let(:wikitext) { "First sentence.Second one. Fine here. In the U.S.A and [[St.Louis]].\n" }

    it 'flags a missing space after a sentence but not initialisms or links' do
      expect(findings.size).to eq(1)
      expect(quotes.first).to include('sentence.Second')
    end
  end

  describe ArticleAuditing::Checks::Language do
    let(:wikitext) { '' }

    context 'with English prose' do
      let(:plaintext) {
 ('The cat sat on the mat and it was happy with the result of the day. ' * 10) }

      it 'finds nothing' do
        expect(findings).to be_empty
      end
    end

    context 'with prose in another language' do
      let(:plaintext) {
 ('El gato se sentó en la alfombra y estaba feliz con el resultado del día. ' * 10) }

      it 'flags it' do
        expect(findings.first['severity']).to eq('must_fix')
      end
    end

    it 'only applies on English-language wikis' do
      es_context = instance_double(ArticleAuditing::Context,
                                   wiki: instance_double(Wiki, language: 'es'))
      expect(described_class.new.applies_to?(es_context)).to be(false)
      expect(described_class.new.applies_to?(context)).to be(true)
    end
  end
end
