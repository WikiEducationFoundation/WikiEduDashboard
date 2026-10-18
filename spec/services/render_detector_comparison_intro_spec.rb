# frozen_string_literal: true

require 'rails_helper'

describe RenderDetectorComparisonIntro do
  let(:path) { Rails.root.join('tmp/detector_comparison_page_spec.yml') }

  after { FileUtils.rm_f(path) }

  it 'renders the preamble and each view description as HTML, keeping the selections' do
    File.write(path, <<~YAML)
      preamble: |
        Some **findings**, with <script>alert(1)</script> left as text.

        Sage Ross
        Wiki Education
      views:
        - key: first
          title: First view
          description: See [Agpedia](https://agpedia.org).
          selection:
            detectors: [p4]
    YAML
    result = described_class.new(path:).result

    expect(result[:preamble_html]).to include('<strong>findings</strong>')
    expect(result[:preamble_html]).not_to include('<script>')
    expect(result[:preamble_html]).to include("Sage Ross<br>\nWiki Education")
    view = result[:views].first
    expect(view).to include(key: 'first', title: 'First view', dataset: 'topics',
                            selection: { 'detectors' => ['p4'] })
    expect(view[:description_html]).to include('<a href="https://agpedia.org">Agpedia</a>')
  end

  it 'reads the page content shipped in config' do
    expect(described_class.new.result[:views].map { |view| view[:key] })
      .to include('pangram-vs-originality')
  end
end
