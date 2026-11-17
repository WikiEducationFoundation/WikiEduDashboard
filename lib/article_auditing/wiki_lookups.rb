# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

module ArticleAuditing
  # General-purpose wiki lookups for the wiki-context checks: which titles
  # exist, what categories pages are in, and matching Wikidata items. No
  # caching or locking here; WikiContext memoizes and serializes the calls.
  class WikiLookups
    TITLE_BATCH = 50

    def initialize(wiki)
      @wiki = wiki
      @api = WikiApi.new(wiki)
    end

    # { input_title => { title:, description: } } for each title that exists
    # as a non-disambiguation page, following normalization and redirects.
    def existing_titles(titles)
      titles.each_slice(TITLE_BATCH).each_with_object({}) do |batch, found|
        found.merge!(existing_batch(batch))
      end
    end

    # Non-hidden categories of +titles+ (up to 50), with how many of the
    # pages are in each: { 'Category:Foo' => 3 }.
    def category_counts(titles)
      pages = @api.query(titles: titles.first(TITLE_BATCH).join('|'), prop: 'categories',
                         clshow: '!hidden', cllimit: 'max', redirects: 1)&.data&.dig('pages')
      Array(pages&.values).flat_map { |page| Array(page['categories']).pluck('title') }.tally
    end

    # [{ id:, label:, description:, enwiki: }] for Wikidata items matching
    # +label+, where enwiki is the title of the item's article on this wiki.
    def wikidata_candidates(label)
      results = wikidata.action('wbsearchentities', search: label, language:, type: 'item',
                                                    limit: 5)&.data&.dig('search') || []
      return [] if results.empty?
      sitelinks = wikidata_sitelinks(results.pluck('id'))
      results.map do |result|
        { id: result['id'], label: result['label'], description: result['description'],
          enwiki: sitelinks[result['id']] }
      end
    end

    private

    def language
      @wiki.language || 'en'
    end

    def wikidata
      @wikidata ||= WikiApi.new(Wiki.get_or_create(language: nil, project: 'wikidata'))
    end

    def existing_batch(batch)
      data = @api.query(titles: batch.join('|'), redirects: 1, prop: 'pageprops|description',
                        ppprop: 'disambiguation')&.data || {}
      resolved = resolution_map(data)
      pages = existing_pages(data)
      batch.each_with_object({}) do |input, found|
        page = pages[resolved.fetch(input, input)]
        found[input] = { title: page['title'], description: page['description'] } if page
      end
    end

    # Existing, non-disambiguation pages in a query response, by title.
    def existing_pages(data)
      Array(data['pages']&.values).reject do |page|
        page.key?('missing') || page.key?('invalid') ||
          page['pageprops']&.key?('disambiguation')
      end.index_by { |page| page['title'] }
    end

    # Maps each input title through the API's normalization and redirects.
    def resolution_map(data)
      steps = Array(data['normalized']) + Array(data['redirects'])
      lookup = steps.to_h { |step| [step['from'], step['to']] }
      lookup.keys.index_with do |from|
        to = lookup[from]
        seen = Set[from]
        to = lookup[to] while lookup.key?(to) && seen.add?(to)
        to
      end
    end

    def wikidata_sitelinks(ids)
      site = "#{language}wiki"
      entities = wikidata.action('wbgetentities', ids: ids.join('|'), props: 'sitelinks',
                                                  sitefilter: site)&.data&.dig('entities') || {}
      entities.transform_values { |entity| entity.dig('sitelinks', site, 'title') }
    end
  end
end
