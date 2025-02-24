# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/replica"
require_dependency "#{Rails.root}/lib/errors/api_error_handling"

#= Imports articles from Wikipedia into the dashboard database
class ArticleImporter
  include ApiErrorHandling

  def initialize(wiki)
    @wiki = wiki
    @articles = []
  end

  def import_articles(ids)
    article_ids = ids.map { |id| { 'mw_page_id' => id } }
    articles_data = []
    article_ids.each_slice(40) do |some_article_ids|
      some_article_data = Replica.new(@wiki).get_existing_articles_by_id some_article_ids
      next if some_article_data.nil?
      articles_data += some_article_data
    end
    return if articles_data.empty?
    import_articles_from_replica_data(articles_data)
  end

  def import_articles_by_title(titles)
    # Slice size is limited by max URI length.
    # 40 is too much for some languages, such as bn.wipedia.org
    titles.each_slice(30) do |some_article_titles|
      params = {
        action: 'query',
        format: 'json',
        prop: 'info',
        titles: some_article_titles.join('|')
      }
      response = api_post(@wiki, params)
      results = response.dig('query', 'pages')
      next if results.blank?
      import_articles_from_title_query(results)
    end
  end

  private

  def import_articles_from_replica_data(articles_data)
    articles = []
    articles_data.each do |article_data|
      articles << Article.new(mw_page_id: article_data['page_id'],
                              title: article_data['page_title'],
                              namespace: article_data['page_namespace'],
                              wiki_id: @wiki.id)
    end
    Article.import articles, on_duplicate_key_update: [:title, :namespace]
  end

  def import_articles_from_title_query(results)
    articles = []
    results.each_value do |page_data|
      next if page_data['missing']
      next if page_data['invalid']
      articles << Article.new(mw_page_id: page_data['pageid'].to_i,
                              title: page_data['title'].tr(' ', '_'),
                              wiki_id: @wiki.id,
                              namespace: page_data['ns'].to_i)
    end
    Article.import articles, on_duplicate_key_update: [:title, :namespace]
  end

  ###############
  # API methods #
  ###############

  def api_post(wiki, params)
    tries ||= 3
    response = do_post(wiki, params)
    return unless response
    parsed_body = JSON.parse(response.body)
    return if parsed_body.empty?
    parsed_body
  rescue StandardError => e
    tries -= 1
    sleep 1 if too_many_requests?(e)
    retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: { params:, api_url: @api_url })
    return nil
  end

  def do_post(wiki, params)
    uri = URI(wiki.api_url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(params)
    https.request(request)
  end

  def too_many_requests?(e)
    return false unless e.instance_of?(MediawikiApi::HttpError)
    e.status == 429
  end
end
