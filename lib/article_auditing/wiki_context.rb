# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/article_auditing/wiki_lookups"

module ArticleAuditing
  # What the wiki around the audited page looks like: the mainspace article
  # the content is meant for (the "target"), its talk page, what links to it,
  # and the general lookups in WikiLookups.
  #
  # Every lookup is lazy and memoized, and all of them go through one lock,
  # so that checks running on parallel threads still make their Wikimedia API
  # requests one at a time.
  class WikiContext
    # User-space pages whose last path segment names no article.
    GENERIC_SANDBOX = /\A(?:sandbox\d*|.*\bsandbox\b.*|draft\d*|test\d*)\z/i
    DRAFT_NAMESPACE = 118

    def initialize(wiki:, title:, namespace:)
      @wiki = wiki
      @title = title
      @namespace = namespace
      @cache = {}
      @lock = Monitor.new
    end

    # The mainspace title this page is, or is a draft of: the title itself in
    # mainspace, the title without "Draft:" in draft space, and the last
    # segment of a user subpage such as User:Example/Marie Curie. Nil for a
    # page like User:Example/sandbox that names no article.
    def target_title
      memo(:target_title) { derive_target_title }
    end

    # Facts about the target article, or nil if there is no target title.
    # exists: false when the target is a redlink.
    def target_page
      memo(:target_page) { target_title && fetch_target_page }
    end

    def target_exists?
      target_page.present? && target_page[:exists]
    end

    # { templates: [...], recent_edits: n } for the target's talk page, or nil.
    def talk_page
      memo(:talk_page) { target_exists? ? fetch_talk_page : nil }
    end

    # Templates (namespace 10) that link to the target and are navboxes.
    def navboxes_linking_target
      memo(:navboxes) { target_title ? fetch_navboxes : [] }
    end

    # Number of mainspace articles linking to the target, capped at 50.
    def incoming_link_count
      memo(:incoming_links) { target_exists? ? fetch_incoming_link_count : 0 }
    end

    # Up to 10 mainspace articles that mention the target title in text but
    # don't link to it: [{ title:, snippet: }].
    def unlinked_mentions
      memo(:unlinked_mentions) { target_title ? fetch_unlinked_mentions : [] }
    end

    # Up to 5 mainspace articles matching the target title in search, with
    # their short descriptions and opening paragraphs.
    def related_articles
      memo(:related_articles) { target_title ? fetch_related_articles : [] }
    end

    # Wikitext of the target's first revision, or nil.
    def target_first_revision_text
      memo(:first_revision) { target_exists? ? fetch_first_revision_text : nil }
    end

    # See WikiLookups#existing_titles.
    def existing_titles(titles)
      titles = titles.compact.map(&:strip).compact_blank.uniq.sort
      memo([:existing_titles, titles]) { lookups.existing_titles(titles) }
    end

    # See WikiLookups#category_counts.
    def category_counts(titles)
      titles = titles.compact.uniq.first(WikiLookups::TITLE_BATCH).sort
      memo([:category_counts, titles]) { titles.empty? ? {} : lookups.category_counts(titles) }
    end

    # See WikiLookups#wikidata_candidates.
    def wikidata_candidates(label)
      memo([:wikidata, label]) { lookups.wikidata_candidates(label) }
    end

    private

    def memo(key)
      @lock.synchronize do
        return @cache[key] if @cache.key?(key)
        @cache[key] = yield
      end
    end

    def api
      @api ||= WikiApi.new(@wiki)
    end

    def lookups
      @lookups ||= WikiLookups.new(@wiki)
    end

    def derive_target_title
      return @title if @namespace.zero?
      return @title.delete_prefix('Draft:') if @namespace == DRAFT_NAMESPACE
      return unless @namespace == Article::Namespaces::USER && @title.include?('/')
      segment = @title.split('/').last.strip.delete_prefix('Draft:')
      segment.match?(GENERIC_SANDBOX) ? nil : segment
    end

    TARGET_QUERY = {
      redirects: 1, prop: 'info|pageprops|categories|templates|pageassessments',
      ppprop: 'wikibase_item|disambiguation', clshow: '!hidden', cllimit: 'max',
      tlnamespace: 10, tllimit: 'max'
    }.freeze

    def fetch_target_page
      page = first_page(api.query(TARGET_QUERY.merge(titles: target_title)))
      return { exists: false, title: target_title } if page.nil? || page.key?('missing')
      target_page_hash(page)
    end

    def target_page_hash(page)
      {
        exists: true, title: page['title'], page_id: page['pageid'], length: page['length'],
        wikibase_item: page.dig('pageprops', 'wikibase_item'),
        disambiguation: page['pageprops']&.key?('disambiguation') || false,
        categories: titles_of(page['categories']), templates: titles_of(page['templates']),
        assessment_class: assessment_class(page['pageassessments'])
      }
    end

    def assessment_class(assessments)
      Array(assessments&.values).map { |assessment| assessment['class'] }.compact_blank.first
    end

    def fetch_talk_page
      page = first_page(api.query(titles: "Talk:#{target_page[:title]}",
                                  prop: 'templates|revisions', tlnamespace: 10, tllimit: 'max',
                                  rvprop: 'timestamp', rvlimit: 50,
                                  rvend: 30.days.ago.iso8601))
      return if page.nil? || page.key?('missing')
      { templates: titles_of(page['templates']), recent_edits: Array(page['revisions']).size }
    end

    NAVBOX_TEMPLATES = 'Template:Navbox|Template:Navbox with collapsible groups'

    def fetch_navboxes
      linking = first_page(api.query(titles: target_title, prop: 'linkshere', lhnamespace: 10,
                                     lhlimit: 50, redirects: 1))
      candidates = titles_of(linking&.dig('linkshere'))
      return [] if candidates.empty?
      pages = api.query(titles: candidates.first(WikiLookups::TITLE_BATCH).join('|'),
                        prop: 'templates', tltemplates: NAVBOX_TEMPLATES, tllimit: 'max')
      Array(pages&.data&.dig('pages')&.values).select { |page| page['templates'].present? }
                                               .pluck('title').sort
    end

    def fetch_incoming_link_count
      page = first_page(api.query(titles: target_page[:title], prop: 'linkshere',
                                  lhnamespace: 0, lhshow: '!redirect', lhlimit: 50))
      Array(page&.dig('linkshere')).size
    end

    def fetch_unlinked_mentions
      quoted = target_title.delete('"')
      results = api.query(list: 'search', srsearch: %("#{quoted}" -linksto:"#{quoted}"),
                          srnamespace: 0, srlimit: 10, srprop: 'snippet')&.data&.dig('search')
      Array(results).reject { |result| result['title'] == target_title }.map do |result|
        { title: result['title'], snippet: strip_tags(result['snippet']) }
      end
    end

    def fetch_related_articles
      pages = api.query(generator: 'search', gsrsearch: target_title, gsrnamespace: 0,
                        gsrlimit: 5, prop: 'description|extracts', exintro: 1, explaintext: 1,
                        exlimit: 5, exchars: 1200)&.data&.dig('pages')
      Array(pages&.values).sort_by { |page| page['index'] || 0 }.map do |page|
        { title: page['title'], description: page['description'], extract: page['extract'] }
      end
    end

    def fetch_first_revision_text
      page = first_page(api.query(titles: target_page[:title], prop: 'revisions', rvdir: 'newer',
                                  rvlimit: 1, rvprop: 'content', rvslots: 'main'))
      page&.dig('revisions', 0, 'slots', 'main', '*')
    end

    def first_page(response)
      response&.data&.dig('pages')&.values&.first
    end

    def titles_of(list)
      Array(list).pluck('title')
    end

    def strip_tags(html)
      ActionView::Base.full_sanitizer.sanitize(html.to_s)
    end
  end
end
