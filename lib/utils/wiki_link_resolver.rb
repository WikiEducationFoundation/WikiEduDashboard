# frozen_string_literal: true

# Pandoc's mediawiki-to-markdown conversion leaves internal/interwiki
# [[wikilink]] targets as the raw wiki target (eg
# "wikipedia:Wikipedia:Notability"), since it has no access to MediaWiki's
# interwiki table and can't resolve them into real URLs on its own. This
# rewrites the targets we can confidently resolve into MediaWiki's external
# link syntax (`[url text]`), which Pandoc already converts correctly.
#
# Anything we're not confident about — category links, image embeds,
# same-page anchors, or namespaces/prefixes we don't recognize — is left
# untouched, so Pandoc handles it exactly as it does today.
class WikiLinkResolver
  # Interwiki project prefixes, mapped to the domain they resolve to by
  # default (English-language, unless overridden by an explicit language
  # sub-prefix, eg the 'eu' in "w:eu:Foo").
  PROJECT_DOMAINS = {
    'w' => 'wikipedia.org', 'wikipedia' => 'wikipedia.org',
    'wikt' => 'wiktionary.org', 'wiktionary' => 'wiktionary.org',
    'n' => 'wikinews.org', 'wikinews' => 'wikinews.org',
    'b' => 'wikibooks.org', 'wikibooks' => 'wikibooks.org',
    'q' => 'wikiquote.org', 'wikiquote' => 'wikiquote.org',
    's' => 'wikisource.org', 'wikisource' => 'wikisource.org',
    'v' => 'wikiversity.org', 'wikiversity' => 'wikiversity.org',
    'voy' => 'wikivoyage.org', 'wikivoyage' => 'wikivoyage.org'
  }.freeze

  # A leading colon (eg "[[:Category:Foo]]") turns these into a normal visible
  # link, so only skip when there's no leading colon to override that.
  SKIPPED_NAMESPACES = /\A(File|Image|Category):/i

  WIKILINK_RE = /\[\[(?<target>[^|\]]+)(?:\|(?<text>[^\]]+))?\]\]/

  def self.resolve(text)
    text.gsub(WIKILINK_RE) { resolve_match(Regexp.last_match) }
  end

  def self.resolve_match(match)
    url = url_for(match[:target].strip)
    url ? "[#{url} #{(match[:text] || match[:target]).strip}]" : match[0]
  end

  def self.url_for(target)
    return if target.start_with?('#') || target =~ SKIPPED_NAMESPACES
    normalized = target.sub(/\A:/, '')
    prefix, colon, rest = normalized.partition(':')
    return "https://meta.wikimedia.org/wiki/#{escape(normalized)}" if colon.empty?
    domain = PROJECT_DOMAINS[prefix.downcase]
    domain && interwiki_url(domain, rest)
  end

  # Handles an optional language sub-prefix, eg the 'eu' in "w:eu:Wikipedia:Genero_oreka".
  def self.interwiki_url(domain, rest)
    lang, colon, page = rest.partition(':')
    if !colon.empty? && lang == lang.downcase && lang.length.between?(2, 3)
      "https://#{lang}.#{domain}/wiki/#{escape(page)}"
    else
      "https://en.#{domain}/wiki/#{escape(rest)}"
    end
  end

  def self.escape(title)
    title.tr(' ', '_')
  end
end
