# frozen_string_literal: true

# The category and template autocompletes query MediaWiki's search API from the
# browser, where WebMock cannot reach. Live searches from CI's shared IP are
# throttled often enough that they return nothing and the expected option never
# appears, so these specs serve canned search results to the browser instead.
#
# `results` maps "host|namespace|srsearch" (exactly as searchForPages in
# utils/api.js builds the request) to the page titles the search should return.
# Any other search gets no results rather than falling through to the network.
module BrowserWikiSearchStubs
  def stub_browser_wiki_search(results)
    source = <<~JS
      (() => {
        const results = #{results.to_json};
        const realFetch = window.fetch.bind(window);
        window.fetch = (input, init) => {
          const url = new URL(typeof input === 'string' ? input : input.url, location.href);
          const params = url.searchParams;
          if (url.pathname !== '/w/api.php' || params.get('list') !== 'search') {
            return realFetch(input, init);
          }
          const key = [url.host, params.get('srnamespace'), params.get('srsearch')].join('|');
          const search = (results[key] || []).map(title => ({ title }));
          return Promise.resolve(new Response(JSON.stringify({ query: { search } }), {
            headers: { 'Content-Type': 'application/json' }
          }));
        };
      })();
    JS
    @browser_wiki_search_stub = page.driver.browser
                                    .execute_cdp('Page.addScriptToEvaluateOnNewDocument', source:)
  end

  def remove_browser_wiki_search_stub
    return unless @browser_wiki_search_stub
    page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument',
                                    identifier: @browser_wiki_search_stub['identifier'])
    @browser_wiki_search_stub = nil
  end
end

RSpec.configure do |config|
  config.include BrowserWikiSearchStubs, type: :feature
  # The injected script belongs to the browser session, which outlives the example.
  config.after(:each, type: :feature, js: true) { remove_browser_wiki_search_stub }
end
