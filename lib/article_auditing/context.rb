# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/article_auditing/wikitext"
require_dependency "#{Rails.root}/lib/article_auditing/llm_check"
require_dependency "#{Rails.root}/lib/article_auditing/wiki_context"

module ArticleAuditing
  # Everything a check might want to know about the audited revision,
  # fetched lazily and memoized. Revisions are immutable, so a Context can be
  # rebuilt at any time from (wiki, mw_rev_id) — that is what lets a single
  # check be re-run later without re-running the whole audit.
  #
  # Wikimedia fetches are sequential. The lazy readers are not thread-safe;
  # call #preload before sharing a Context across threads.
  class Context
    attr_reader :wiki, :mw_rev_id

    def initialize(wiki:, mw_rev_id:)
      @wiki = wiki
      @mw_rev_id = mw_rev_id
    end

    # Fetches every input the checks use, so that the Context can be shared
    # across threads.
    def preload
      revision_info
      wikitext
      plaintext
      prose_text
      wiki_context.target_page
      self
    end

    # { title:, namespace:, page_id:, parent_id:, timestamp: } or nil if the
    # revision is missing or deleted.
    def revision_info
      @revision_info ||= fetch_revision_info
    end

    def title
      revision_info&.dig(:title)
    end

    def namespace
      revision_info&.dig(:namespace)
    end

    def page_id
      revision_info&.dig(:page_id)
    end

    # The revision is the first one of its page.
    def page_creation?
      revision_info&.dig(:parent_id)&.zero?
    end

    def mainspace?
      namespace == Article::Namespaces::MAINSPACE
    end

    # The page's surroundings on the wiki, including the mainspace article
    # it is a draft of. See WikiContext.
    def wiki_context
      @wiki_context ||= WikiContext.new(wiki:, title:, namespace:)
    end

    # The content is a new article rather than an improvement to an existing
    # one: a mainspace page's first revision, or a draft whose target article
    # doesn't exist yet (or whose target can't be told from its title).
    def new_article?
      return page_creation? if mainspace?
      !wiki_context.target_exists?
    end

    def wikitext
      @wikitext ||= article_content.revision_wikitext(mw_rev_id).to_s
    end

    def parsed_wikitext
      @parsed_wikitext ||= Wikitext.new(wikitext)
    end

    def html
      @html ||= article_content.revision_html(mw_rev_id)[:html].to_s
    end

    # Rendered prose: the HTML with reference lists, citation markers, style
    # and edit chrome removed. Infoboxes and tables are kept, since findings
    # may quote them.
    def plaintext
      @plaintext ||= html_to_plaintext(html)
    end

    # Running prose only, without infoboxes, tables, figures or citations:
    # the text AI detectors score, matching GetRevisionPlaintext.
    def prose_text
      @prose_text ||= html_to_plaintext(html, extra_selectors: 'table, figure, img, cite')
    end

    # The system prompt blocks shared by every LLM check for this revision:
    # the stable instructions, then the article itself. The article block is
    # a cache breakpoint, so every LLM check after the first reads it from
    # the prompt cache instead of paying for it again.
    def llm_system_blocks
      [
        { text: LlmCheck.system_prompt, cache: false },
        { text: article_block, cache: true }
      ]
    end

    private

    def article_content
      @article_content ||= WikiApi::ArticleContent.new(wiki)
    end

    def fetch_revision_info
      params = { prop: 'revisions|info', revids: mw_rev_id, rvprop: 'ids|timestamp' }
      response = WikiApi.new(wiki).query(params)
      return if response.nil? || response.data['badrevids'].present?
      page = response.data['pages']&.values&.first
      return if page.nil?
      revision = page['revisions']&.first || {}
      { title: page['title'], namespace: page['ns'], page_id: page['pageid'],
        parent_id: revision['parentid'], timestamp: revision['timestamp'] }
    end

    def article_block
      <<~ARTICLE
        <article #{article_attributes}>
        #{wikitext}
        </article>
      ARTICLE
    end

    def article_attributes
      attributes = { title:, namespace:, revision: mw_rev_id, wiki: wiki.domain,
                     target_title: wiki_context.target_title,
                     target_exists: (wiki_context.target_exists? if wiki_context.target_title) }
      attributes.compact.map { |name, value| %(#{name}="#{CGI.escapeHTML(value.to_s)}") }.join(' ')
    end

    def html_to_plaintext(source, extra_selectors: nil)
      doc = Nokogiri::HTML(source)
      selectors = ['style, link, sup.reference, ol.references, .mw-editsection, .reflist',
                   extra_selectors].compact.join(', ')
      doc.css(selectors).each(&:remove)
      doc.text.gsub(/[ \t]+/, ' ').gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
