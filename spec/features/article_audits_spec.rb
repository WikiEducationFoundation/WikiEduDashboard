# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe 'Article Audit admin pages', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:wikitext) { "==Introduction==\n'''Acme''' is a world-class company." }
  let(:context) do
    instance_double(ArticleAuditing::Context,
                    revision_info: { title: 'Acme', namespace: 2, page_id: 9, parent_id: 0 },
                    title: 'Acme', namespace: 2, page_id: 9,
                    parsed_wikitext: ArticleAuditing::Wikitext.new(wikitext),
                    wikitext:, plaintext: 'Introduction Acme is a world-class company.',
                    prose_text: 'Acme is a world-class company.', mainspace?: false,
                    page_creation?: true, new_article?: true, mw_rev_id: 42,
                    wiki_context: instance_double(
                      ArticleAuditing::WikiContext, target_title: nil, target_page: nil,
                      target_exists?: false, talk_page: nil, target_first_revision_text: nil,
                      existing_titles: {}, category_counts: {}
                    ),
                    wiki: Wiki.get_or_create(language: 'en', project: 'wikipedia'),
                    llm_system_blocks: [{ text: 'article', cache: true }])
  end
  let(:adapter) { instance_double(Llm::AnthropicAdapter) }
  let(:tone_finding) do
    { 'severity' => 'should_fix', 'title' => 'Peacock term', 'explanation' => 'Says who?',
      'section' => 'Lead', 'quote' => 'a world-class company', 'suggestion' => 'a company',
      'policy_refs' => ['WP:PEACOCK'] }
  end

  before do
    allow(Features).to receive(:article_audit?).and_return(true)
    # Never call Pangram for real, even if a key is configured locally.
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('pangram_api_key').and_return(nil)
    allow(ArticleAuditing::Context).to receive(:new).and_return(context)
    allow(context).to receive(:preload).and_return(context)
    allow(Llm::Client).to receive(:adapter).and_return(adapter)
    allow(adapter).to receive(:complete) do |user:, **|
      findings = user.include?('Check: tone') ? [tone_finding] : []
      Llm::Response.new(text: '{}', json: { 'findings' => findings }, model: 'claude-opus-5-5',
                        usage: { 'input_tokens' => 100, 'output_tokens' => 20 })
    end
    login_as(admin)
  end

  after { logout }

  it 'runs an audit from a URL and shows the report' do
    visit '/article_audits'
    expect(page).to have_content 'Article Audit'
    fill_in 'Article URL', with: 'https://en.wikipedia.org/w/index.php?title=User:Ex/Acme&oldid=42'
    click_button 'Run audit'

    expect(page).to have_css('h1', text: 'Acme')
    expect(page).to have_content 'Complete'
    expect(page).to have_css('h2', text: 'Tone')
    expect(page).to have_content 'Peacock term'
    expect(page).to have_css('.article-audit-finding__quote', text: 'a world-class company')
    expect(page).to have_css('h2', text: 'Structure')
    expect(page).to have_css('.article-audit-finding--must_fix')
    expect(page).to have_content 'sourcing.unsourced_claims'
    expect(page).to be_axe_clean

    within('tr', text: 'tone') do
      expect(page).to have_css('.article-audit__runs', text: '1')
      click_button 'Re-run'
      expect(page).to have_css('.article-audit__runs', text: '2')
    end

    click_link 'Article Audit'
    expect(page).to have_link 'Acme'
  end
end
