require "#{Rails.root}/lib/replica"

#= Imports articles from Wikipedia into the dashboard database
class ArticleImporter
  def initialize(wiki)
    @wiki = wiki
  end

  def import_articles(ids)
    # TODO: pass the ids directly
    page_ids = ids.map { |id| { 'id' => id } }
    articles_data = Utils.chunk_requests(page_ids) do |block|
      Replica.new(@wiki).get_existing_articles_by_id block
    end
    articles = articles_data.map do |a|
      Article.new(id: a['page_id'], # TODO: Stop writing ID
                  native_id: a['page_id'],
                  title: a['page_title'],
                  namespace: a['page_namespace'],
                  wiki_id: @wiki.id)
    end
    Article.import articles
  end

  def import_articles_by_title(titles)
    titles.each_slice(40) do |some_article_titles|
      query = { prop: 'info',
                titles: some_article_titles }
      response = WikiApi.new(@wiki).query(query)
      next if response.nil?
      results = response.data
      next if results.empty?
      results = results['pages']
      articles = []
      results.each do |_id, page_data|
        next if page_data['missing']
        articles << Article.new(id: page_data['pageid'].to_i, # TODO: Stop writing to ID
                                native_id: page_data['pageid'].to_i,
                                title: page_data['title'].tr(' ', '_'),
                                namespace: page_data['ns'].to_i,
                                wiki_id: @wiki.id)
      end
      Article.import articles
    end
  end
end
