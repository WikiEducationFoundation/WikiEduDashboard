# Gets the text of a Wikipedia page at given timestamp,
# fetches the text, and runs it through AI detectors

require_relative './pangram_api'
require_relative './gpt_zero_api'

class RevAnalyzer
  attr_reader :plain_text, :html, :rev_id, :redirect,
              :zero_max_generated_prob, :zero_suspected_sentence_count, :zero_most_suspect_sentence,
              :pangram_ai_likelihood, :pangram_average_ai_likelihood, :pangram_max_ai_likelihood, :pangram_fraction_ai_content,
              :pangram_predicted_ai_window_count, :pangram_predicted_llm, :pangram_result
  EN_WIKI = Wiki.get_or_create(language: 'en', project: 'wikipedia')

  def initialize(mw_page_id, timestamp)
    @mw_page_id = mw_page_id
    @timestamp = timestamp
  end

  def analyze
    @rev_at_date = rev_at_date(@mw_page_id, @timestamp)
    return unless @rev_at_date
    return unless @rev_at_date['*']
    @redirect =  @rev_at_date['*'].include? '#REDIRECT'
    return if @redirect
    @rev_id = @rev_at_date['revid']
    @html = html_for_rev(@rev_id)
    @plain_text = plain_text
  end

  def gpt_zero
    return unless @plain_text
    zero = GptZeroApi.new
    zero.predict(@plain_text)
    @zero_max_generated_prob = zero.top_generated_prob
    @zero_suspected_sentence_count = zero.suspected_sentences.count
    @zero_most_suspect_sentence = zero.most_suspicious_sentence_text
  end

  def pangram
    return unless @plain_text
    pangram = PangramApi.new
    pangram.inference @plain_text
    @pangram_result = pangram.result
    @pangram_ai_likelihood = pangram.ai_likelihood
    @pangram_average_ai_likelihood = pangram.average_ai_likelihood
    @pangram_max_ai_likelihood = pangram.max_ai_likelihood
    @pangram_fraction_ai_content = pangram.fraction_ai_content
    @pangram_predicted_ai_window_count = pangram.predicted_ai_window_count
    @pangram_predicted_llm = pangram.predicted_llm
  end

  # private-ish
  def rev_at_date(mw_page_id, timestamp, wiki = EN_WIKI)
    query_params = {
      prop: 'revisions',
      pageids: mw_page_id,
      rvlimit: 1,
      rvdir: 'older',
      rvstart: timestamp.to_datetime.strftime('%Y%m%d%H%M%S'),
      rvprop: 'content|ids|user|timestamp'
    }
    resp = WikiApi.new(wiki).query query_params
    rev = resp.data.dig('pages', mw_page_id.to_s, 'revisions')&.first
    rev
  end

  def html_for_rev(revid, wiki = EN_WIKI)
    # https://en.wikipedia.org/w/api.php?action=parse&oldid=952185129
    params = { oldid: revid }
    resp = WikiApi.new(wiki).send(:api_client).send('action', 'parse', params)
    resp.data.dig('text', '*')
  end

  def plain_text
    ActionView::Base.full_sanitizer.sanitize(@html).gsub('[edit]', '')
  end

  def plain_text_length
    @plain_text&.length || 0
  end
end