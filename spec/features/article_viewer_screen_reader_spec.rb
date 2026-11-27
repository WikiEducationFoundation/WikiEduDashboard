# frozen_string_literal: true

require 'rails_helper'

# Reads the Article Viewer's authorship highlighting with Orca.
# Run with bin/screen-reader-spec; other runs leave it out.
describe 'Article Viewer authorship highlighting, read by a screen reader',
         type: :feature, js: true, screen_reader: true do
  let(:course) { create(:course, start: '2017-01-01', end: '2020-01-01') }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:article) { create(:article, title: 'Nancy_Tuana') }

  before do
    course.campaigns << Campaign.first
    create(:courses_user, course:, user:)
    create(:articles_course, course:, article:, user_ids: [user.id])
  end

  # WhoColor markup: one span per token, classed by the MediaWiki user id of the
  # token's author. 319203 is Ragesoss; 9 stands in for everyone else.
  def whocolor_response
    tokens = []
    paragraph = lambda do |words|
      spans = words.map do |editor, word|
        tokens << [0, word, 1, [], [], editor.to_s, 0]
        id = "token-#{tokens.size}"
        %(<span class="editor-token token-editor-#{editor}" id="#{id}">#{word}</span>)
      end
      "<p>#{spans.join(' ')}</p>"
    end
    html = paragraph.call([[9, 'The'], [9, 'compound'], [319203, 'is'], [319203, 'highly'],
                           [319203, 'toxic'], [9, 'to'], [9, 'fish.']]) +
           paragraph.call([[319203, 'Researchers'], [319203, 'found'], [9, 'that'],
                           [9, 'the'], [9, 'effect'], [9, 'persists.']]) +
           paragraph.call([[9, 'Water'], [319203, 'quality'], [9, 'matters.']])
    { success: true, extended_html: %(<div class="mw-parser-output">#{html}</div>), tokens: }
  end

  # The WikiWho API is answered in the page, so the spec doesn't depend on it.
  def stub_whocolor
    page.execute_script(<<~JS, whocolor_response.to_json)
      const body = arguments[0];
      const realFetch = window.fetch;
      window.fetch = (url, options) => {
        if (!String(url).includes('wikiwho-api')) return realFetch(url, options);
        return Promise.resolve(new Response(body, { headers: { 'Content-Type': 'application/json' } }));
      };
    JS
  end

  def open_highlighted_article
    visit "/courses/#{course.slug}/articles"
    stub_whocolor
    find('button.icon-article-viewer').click
    expect(page).to have_css('.parsed-article .user-highlight-1', count: 6, wait: 30)
  end

  it 'names the student once per highlighted run when reading the article' do
    open_highlighted_article
    move_screen_reader_to('.parsed-article p')
    spoken = screen_reader_say_all.map(&:strip)
    # Say All carries on past the article into the legend and footer.
    article = spoken.take(spoken.index('matters.') + 1)
    expect(article).to eq(['The', 'compound', 'Added by Ragesoss', 'is', 'highly', 'toxic',
                           'to', 'fish.',
                           'Added by Ragesoss', 'Researchers', 'found', 'that', 'the',
                           'effect', 'persists.',
                           'Water', 'Added by Ragesoss', 'quality', 'matters.'])
  end

  it 'names the student on entering a run, not on each word, when reading word by word' do
    open_highlighted_article
    move_screen_reader_to('.parsed-article p')
    words = Array.new(8) { screen_reader_next_word.map(&:strip) }
    expect(words).to eq([['The'], ['compound'], ['Added'], ['by'], ['Ragesoss'], ['is'],
                         ['highly'], ['toxic']])
  end

  # The legend button scrolls to a paragraph with the student's text, but moves
  # focus to their highlighted run within it rather than the whole paragraph.
  def press_legend_button
    # Orca only follows focus here after real input, which this caret move provides.
    move_screen_reader_to('.parsed-article p')
    page.execute_script("document.querySelector('button.article-viewer-legend-button').focus()")
    sleep 1
    screen_reader_speech_during { system('xdotool', 'key', 'Return', exception: true) }
      .map(&:strip)
  end

  it "announces the student's highlighted run, not its paragraph, from the legend button" do
    open_highlighted_article
    spoken = press_legend_button
    expect(spoken).to include('Added by Ragesoss')
    expect(spoken.join(' ')).not_to include('The compound')
  end

  it "continues reading from the start of the student's run after the legend button" do
    open_highlighted_article
    press_legend_button
    words = Array.new(4) { screen_reader_next_word.map(&:strip) }
    expect(words).to eq([['Added'], ['by'], ['Ragesoss'], ['is']])
  end
end
