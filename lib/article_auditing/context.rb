# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"
require_dependency "#{Rails.root}/lib/article_auditing/wikitext"
require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

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

    # Fetches every input the LLM checks and quote validation use.
    def preload
      revision_info
      wikitext
      plaintext
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
        <article title="#{title}" namespace="#{namespace}" revision="#{mw_rev_id}" wiki="#{wiki.domain}">
        #{wikitext}
        </article>
      ARTICLE
    end

    def html_to_plaintext(source)
      doc = Nokogiri::HTML(source)
      doc.css('style, link, sup.reference, ol.references, .mw-editsection, .reflist').each(&:remove)
      doc.text.gsub(/[ \t]+/, ' ').gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
