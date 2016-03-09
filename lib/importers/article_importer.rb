require "#{Rails.root}/lib/replica"

#= Imports articles from Wikipedia into the dashboard database
class ArticleImporter
  def self.import_articles(ids)
    article_ids = ids.map { |id| { 'id' => id } }
    articles_data = []
    article_ids.each_slice(40) do |some_article_ids|
      articles_data += Replica.get_existing_articles_by_id some_article_ids
    end
    return if articles_data.empty?
    articles = []
    articles_data.each do |article_data|
      articles << Article.new(id: article_data['page_id'],
                              title: article_data['page_title'],
                              namespace: article_data['page_namespace'],
                              wiki_id: Wiki.default_wiki.id)
    end
    Article.import articles
  end

  def self.import_articles_by_title(titles)
    titles.each_slice(40) do |some_article_titles|
      query = { prop: 'info',
                titles: some_article_titles }
      response = WikiApi.new.query(query)
      next if response.nil?
      results = response.data
      next if results.empty?
      results = results['pages']
      articles = []
      results.each do |_id, page_data|
        next if page_data['missing']
        articles << Article.new(id: page_data['pageid'].to_i,
                                title: page_data['title'].tr(' ', '_'),
                                namespace: page_data['ns'].to_i)
      end
      Article.import articles
    end
  end
end
