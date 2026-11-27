# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

#= Reads a page's current wikitext through the action API, for code that edits
#= the page next. WikiApi#get_page_content uses index.php?action=raw, which
#= Wikimedia's CDN caches and an edit does not purge, so its text can be
#= minutes old. Same contract: '' for a missing page, PageFetchError if the
#= wiki can't be read.
class CurrentPageContent
  def self.fetch(wiki, title)
    response = WikiApi.new(wiki).query(titles: title, prop: 'revisions', rvprop: 'content',
                                       rvslots: 'main', formatversion: 2)
    raise WikiApi::PageFetchError.new(title, nil) if response.nil?

    response.data.dig('pages', 0, 'revisions', 0, 'slots', 'main', 'content') || ''
  end
end
