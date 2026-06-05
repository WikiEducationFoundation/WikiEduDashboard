require_dependency "#{Rails.root}/lib/wiki_api"

# Given an ArticlesCourses record, find the cumulative diff URL from the first
# edit through end of the course.
# (It would be even better to get the cumulative diff through the last student edit.)
class CumulativeDiff
  def initialize(article_course)
    @ac = article_course
    @mw_page_id = @ac.article.mw_page_id
    @wiki = @ac.article.wiki
    @wiki_api = WikiApi.new(@wiki)
    @end_time = @ac.course.end
  end

  def generate_diff_url
    @revision_at_start = rev_at_date(@ac.course.start, @mw_page_id)
    @revision_at_end = rev_at_date(@ac.course.end, @mw_page_id)
    if @revision_at_start.nil?
      "https://#{@wiki.domain}/w/index.php?oldid=#{@revision_at_end}"
    else
      "https://#{@wiki.domain}/w/index.php?diff=#{@revision_at_end}&oldid=#{@revision_at_start}"
    end
  end

  private

  def rev_at_date(timestamp, page_id)
    query_params = {
      prop: 'revisions',
      pageids: page_id,
      rvlimit: 1,
      rvdir: 'older',
      rvstart: timestamp.to_datetime.strftime('%Y%m%d%H%M%S'),
      rvprop: 'ids|timestamp'
    }
    resp = @wiki_api.query query_params
    rev = resp.data.dig('pages', page_id.to_s, 'revisions')&.first
    return unless rev
    rev['revid']
  end
end
