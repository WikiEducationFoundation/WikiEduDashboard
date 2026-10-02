# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

# Given an ArticlesCourses record, finds the revision of the article at the
# start and end of the course, so the text added over the whole course can be
# fetched as one diff. (It would be even better to end at the last student edit.)
class CumulativeDiff
  def initialize(article_course)
    @ac = article_course
    @mw_page_id = @ac.article.mw_page_id
    @wiki = @ac.article.wiki
    @wiki_api = WikiApi.new(@wiki)
  end

  # In the shape WikiUrlParser#revision_target uses: the whole end revision for
  # an article that did not exist at course start, otherwise the diff between
  # the start and end revisions. Nil if the page has no revision by course end
  # or was not edited during the course.
  def revision_target
    end_rev = rev_at_date(@ac.course.end)
    return if end_rev.nil?

    start_rev = rev_at_date(@ac.course.start)
    return { rev_id: end_rev, from_rev: nil, diff_mode: false } if start_rev.nil?
    return if start_rev == end_rev

    { rev_id: end_rev, from_rev: start_rev, diff_mode: true }
  end

  def generate_diff_url
    target = revision_target
    return unless target
    return "https://#{@wiki.domain}/w/index.php?oldid=#{target[:rev_id]}" unless target[:diff_mode]

    "https://#{@wiki.domain}/w/index.php?diff=#{target[:rev_id]}&oldid=#{target[:from_rev]}"
  end

  private

  def rev_at_date(timestamp)
    query_params = {
      prop: 'revisions',
      pageids: @mw_page_id,
      rvlimit: 1,
      rvdir: 'older',
      rvstart: timestamp.to_datetime.strftime('%Y%m%d%H%M%S'),
      rvprop: 'ids|timestamp'
    }
    resp = @wiki_api.query query_params
    rev = resp&.data&.dig('pages', @mw_page_id.to_s, 'revisions')&.first
    rev && rev['revid']
  end
end
