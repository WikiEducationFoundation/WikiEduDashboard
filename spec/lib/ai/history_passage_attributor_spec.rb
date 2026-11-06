# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/history_passage_attributor"

describe HistoryPassageAttributor do
  let(:wiki) { Wiki.default_wiki }
  let(:passage) { 'This paragraph was pasted in at once.' }
  # Newest first: the passage is present in revisions 10 through 7.
  let(:texts) do
    { 10 => "Intro.\n\n#{passage}", 9 => "Intro.\n\n#{passage}", 8 => passage,
      7 => "#{passage}[1]", 6 => 'Intro.', 5 => 'Intro.', 4 => '' }
  end
  let(:revisions) { texts.keys.map { |revid| { 'revid' => revid } } }

  before do
    texts.each do |rev_id, text|
      allow(GetRevisionPlaintext).to receive(:new).with(rev_id, wiki, diff_mode: false)
        .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
    end
  end

  def word_counts(revisions, complete: true)
    described_class.new(passages: [passage], revisions:, complete:, wiki:).word_counts
  end

  it 'attributes a passage to the oldest revision of its unbroken run' do
    expect(word_counts(revisions)).to eq(7 => 7)
  end

  it 'attributes a passage present since page creation to the first revision' do
    expect(word_counts(revisions.first(4))).to eq(7 => 7)
  end

  it 'does not attribute a passage whose run continues past the history fetched' do
    expect(word_counts(revisions.first(3), complete: false)).to be_empty
  end
end
