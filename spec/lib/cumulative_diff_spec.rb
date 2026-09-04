# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/cumulative_diff"

describe CumulativeDiff do
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) { create(:article, wiki_id: enwiki.id, mw_page_id: 77) }
  let(:course) { create(:course, start: Date.new(2021, 1, 10), end: Date.new(2021, 5, 10)) }
  let(:articles_course) { create(:articles_course, article:, course:) }

  # Keyed by date: the course end is stored as the last second of the day.
  def stub_revisions(at_end:, at_start:)
    responses = { '20210510' => at_end, '20210110' => at_start }
    allow_any_instance_of(WikiApi).to receive(:query) do |_api, params|
      revid = responses.fetch(params[:rvstart][0, 8])
      data = { 'pages' => { '77' => { 'revisions' => (revid ? [{ 'revid' => revid }] : []) } } }
      instance_double(MediawikiApi::Response, data:)
    end
  end

  it 'targets the diff between the revisions at course start and end' do
    stub_revisions(at_end: 500, at_start: 400)

    diff = described_class.new(articles_course)
    expect(diff.revision_target).to eq(rev_id: 500, from_rev: 400, diff_mode: true)
    expect(diff.generate_diff_url).to eq('https://en.wikipedia.org/w/index.php?diff=500&oldid=400')
  end

  it 'targets the whole end revision when the article did not exist at course start' do
    stub_revisions(at_end: 500, at_start: nil)

    diff = described_class.new(articles_course)
    expect(diff.revision_target).to eq(rev_id: 500, from_rev: nil, diff_mode: false)
    expect(diff.generate_diff_url).to eq('https://en.wikipedia.org/w/index.php?oldid=500')
  end

  it 'has no target when the article was not edited during the course or does not exist' do
    stub_revisions(at_end: 500, at_start: 500)
    expect(described_class.new(articles_course).revision_target).to be_nil

    stub_revisions(at_end: nil, at_start: nil)
    expect(described_class.new(articles_course).generate_diff_url).to be_nil
  end
end
