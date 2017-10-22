# frozen_string_literal: true

require "#{Rails.root}/lib/replica"

#= Imports articles from Wikipedia into the dashboard database
class ArticleImporter
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
    titles.each_slice(40) do |some_article_titles|
      query = { prop: 'info', titles: some_article_titles }
      response = WikiApi.new(@wiki).query(query)
      results = response&.data
      next if results.blank?
      results = results['pages']
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
    Article.import articles
  end

  def import_articles_from_title_query(results)
    articles = []
    results.each do |_id, page_data|
      next if page_data['missing']
      articles << Article.new(mw_page_id: page_data['pageid'].to_i,
                              title: page_data['title'].tr(' ', '_'),
                              wiki_id: @wiki.id,
                              namespace: page_data['ns'].to_i)
    end
    Article.import articles
  end
end
