# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/source_verification_example_store"

# These specs run against whatever has been harvested into the prototype
# example store (data/source_verification_examples.json, populated via
# `rake source_verification:harvest_articles`). Each scenario picks a
# stored example with a different shape, so running with SCREENSHOT=after
# produces a gallery of the page's variations. Scenarios skip when no
# matching example has been harvested.
describe 'Source verification prototype page', type: :feature, js: true do
  let(:user) { create(:user) }

  before { login_as(user) }

  after { logout }

  def visit_example(example)
    skip 'no matching example in the harvested collection' if example.nil?
    visit "/source_verification?example_id=#{example[:id]}"
  end

  it 'serves a random example when none is specified' do
    skip 'no harvested examples' if SourceVerificationExampleStore.count.zero?
    visit '/source_verification'

    expect(page).to have_css 'blockquote'
  end

  it 'serves a simple web-cited claim' do
    example = SourceVerificationExampleStore.all.find do |e|
      e[:claim] == e[:sentence] && e[:citations].any? { |c| c[:urls].present? }
    end
    visit_example(example)

    expect(page).to have_content example[:claim]
    expect(page).to have_link href: example[:citations].first[:urls].first
  end

  it 'highlights a partial-sentence claim within its full sentence' do
    example = SourceVerificationExampleStore.all.find { |e| e[:claim] != e[:sentence] }
    visit_example(example)

    expect(page).to have_css 'mark', text: example[:claim]
    expect(page).to have_content example[:sentence]
  end

  it 'serves a claim cited to multiple sources' do
    example = SourceVerificationExampleStore.all.find { |e| e[:citations].length > 1 }
    visit_example(example)

    example[:citations].each do |citation|
      expect(page).to have_content citation[:citation_text].slice(0, 60)
    end
  end

  it 'serves a claim whose source has no web link' do
    example = SourceVerificationExampleStore.all.find do |e|
      e[:citations].all? { |c| c[:urls].blank? }
    end
    visit_example(example)

    expect(page).to have_content example[:claim]
    expect(page).to have_content 'no web link'
  end

  it 'acknowledges a submitted response' do
    example = SourceVerificationExampleStore.random
    visit_example(example)

    choose 'response_supports'
    click_button '[Submit button label]'

    expect(page).to have_content 'Acknowledgment'
    expect(page).to have_content 'supports'
  end
end
