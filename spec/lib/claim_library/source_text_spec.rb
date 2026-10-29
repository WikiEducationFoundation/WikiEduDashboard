# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/source_text"

describe ClaimLibrary::SourceText do
  it 'keeps the paragraphs of a web page and drops its chrome' do
    html = <<~HTML
      <html><head><style>p { color: red }</style><script>track()</script></head>
      <body><nav>Home | News</nav>
      <h1>Regulators eye India's surrogacy sector</h1>
      <p>It still comes to roughly   a third of the price
         compared with the UK.</p>
      <footer>Copyright</footer></body></html>
    HTML
    text = described_class.extract(html, 'text/html; charset=utf-8')
    expect(text).to eq("Regulators eye India's surrogacy sector\n\n" \
                       'It still comes to roughly a third of the price compared with the UK.')
  end

  it 'reads a journal article in JATS XML without its citation markers' do
    xml = <<~XML
      <article><front><article-meta><title-group>
        <article-title>Surrogacy in India</article-title></title-group></article-meta></front>
      <body><p>The market grew steadily<xref ref-type="bibr">[3]</xref>.</p></body>
      <back><ref-list><ref>Smith 2001</ref></ref-list></back></article>
    XML
    text = described_class.extract(xml, 'application/xml')
    expect(text).to eq("Surrogacy in India\n\nThe market grew steadily.")
  end

  it 'treats a PDF as unreadable when pdftotext is not installed' do
    allow(described_class).to receive(:pdftotext_available?).and_return(false)
    expect(described_class.extract('%PDF-1.4', 'application/pdf')).to eq('')
  end
end
