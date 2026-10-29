# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/verifier_comparison"
require "#{Rails.root}/lib/claim_library/library"

describe ClaimLibrary::VerifierComparison do
  let(:library) do
    library = ClaimLibrary::Library.new('/nonexistent/library.jsonl')
    library.add([judged_record,
                 judged_record(verdict: 'unsupported', flags: ['time_drift'],
                               sentence: 'The Act was passed in 2021.'),
                 library_record(sentence: 'Unjudged, so not compared.')])
    library
  end
  let(:fetcher) do
    source = ClaimLibrary::Source.read(url: 'https://x', read_from: 'https://x', text: 'the text')
    instance_double(ClaimLibrary::SourceFetcher, fetch: source)
  end
  let(:baseline) { "#{Rails.root}/lib/claim_library/verifiers/always_full_support.rb" }

  def comparison(command)
    described_class.new(library:, command:, fetcher:).run
  end

  it 'measures the baseline verifier against the human judgments' do
    result = comparison("ruby #{baseline}")
    expect(result.agreement).to eq(0.5)
    expect(result.per_verdict).to eq('full_support' => [1.0, 1], 'unsupported' => [0.0, 1])
    expect(result.per_flag).to eq('time_drift' => [0.0, 1])
    expect(result.confusion).to eq('full_support' => { 'full_support' => 1 },
                                   'unsupported' => { 'full_support' => 1 })
  end

  it 'hands the verifier the claim and the source text' do
    echo = %(ruby -rjson -e 'c = JSON.parse($stdin.read); ) +
           %(v = c["source_text"] == "the text" ? "unsupported" : "error"; ) +
           %(puts JSON.generate("verdict" => v)')
    expect(comparison(echo).per_verdict['unsupported']).to eq([1.0, 1])
  end

  it 'counts a verifier that fails or answers nonsense as an error, not a match' do
    result = comparison('ruby -e "exit 1"')
    expect(result.results.map(&:machine)).to all(eq('error'))
    expect(result.agreement).to eq(0.0)
  end

  it 'writes the comparison as Markdown' do
    markdown = comparison("ruby #{baseline}").to_markdown
    expect(markdown).to include('Agreement on 2 judged claims: 50%')
    expect(markdown).to include('| time_drift | 1 | 0% |')
    expect(markdown).to include('| unsupported | full_support | 1 |')
  end
end
