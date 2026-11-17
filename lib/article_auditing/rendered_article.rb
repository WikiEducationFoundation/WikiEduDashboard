# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/context"

module ArticleAuditing
  # The audited revision's rendered HTML and wikitext, for the report's
  # side-by-side view. Nothing is stored with the audit: the article is
  # fetched from the wiki and cached, which is safe because a revision never
  # changes. It also means a revision deleted on the wiki drops out of the
  # report rather than living on in our database.
  #
  # RunArticleAudit writes the cache when it has fetched the article anyway,
  # so a report viewed soon after its audit doesn't fetch it again. Entries
  # are compressed: a long article's HTML runs to a megabyte or two.
  module RenderedArticle
    EXPIRES_IN = 1.day

    module_function

    # { html:, wikitext: }, or nil if the revision can't be fetched.
    def fetch(wiki, mw_rev_id)
      Rails.cache.fetch(key(wiki, mw_rev_id), expires_in: EXPIRES_IN, compress: true,
                                              skip_nil: true) do
        from_context(Context.new(wiki:, mw_rev_id:))
      end
    end

    def store(context)
      article = from_context(context)
      return if article.nil?
      Rails.cache.write(key(context.wiki, context.mw_rev_id), article,
                        expires_in: EXPIRES_IN, compress: true)
    end

    def from_context(context)
      return if context.html.blank?
      { html: context.html, wikitext: context.wikitext }
    end

    def key(wiki, mw_rev_id)
      "article_audit_article/#{wiki.id}/#{mw_rev_id}"
    end
  end
end
