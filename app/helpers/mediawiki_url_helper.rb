# frozen_string_literal: true

module MediawikiUrlHelper
  # Converts the title component of MediaWiki page title
  # into a valid URL component to reach that page.
  # Can be used for usernames or mainspace titles.
  def url_encoded_mediawiki_title(title)
    # Convert spaces to underscores, then URL-encode the rest
    # The spaces-to-underscores is the MediaWiki convention, which we replicate
    # for handling usernames in dashboard urls.
    # This is more aggressive encoding that we really need, since most punctuation
    # with the exception of ? & and possibly other characters used for query params
    # are not escaped by default in MediaWiki. But the escaped versions will also work.
    CGI.escape(title.tr(' ', '_'))
  end
end
