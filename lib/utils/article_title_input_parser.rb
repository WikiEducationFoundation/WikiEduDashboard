# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

#= Works out which page a student means from what they enter in an article
#= title input: a title, a [[wikilink]], or a pasted URL of the article, its
#= edit or history page, a diff or an old revision. Links that identify a
#= revision or page only by id carry no title, so those come back as ids for
#= the caller to look up on the wiki. At most one of title, revision_id and
#= page_id is set.
class ArticleTitleInputParser
  attr_reader :title, :revision_id, :page_id

  # A scheme, or a bare wiki host followed by a path.
  URL_START = %r{\A(?:(?:https?:)?//|[\w.-]+\.org/)}i
  WIKILINK = /\A\[\[(?<target>[^|\]]*)(?:\|[^\]]*)?\]\]\z/

  def initialize(input)
    @input = input.to_s.strip
    parse
  end

  private

  def parse
    page = if @input.match?(URL_START)
             WikiUrlParser.new(@input)
           else
             WikiUrlParser.for_page_name(@input[WIKILINK, :target] || @input)
           end
    @title = page.title
    # A diff names the edit it shows, and its oldid is an earlier revision.
    @revision_id = page.diff || page.oldid unless @title
    @page_id = page.curid unless @title || @revision_id
  end
end
