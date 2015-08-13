require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/grok"
require 'mediawiki_api'

#= Creates Articles for a category
class CategoryImporter
  ################
  # Entry points #
  ################
  def self.import_category(category)
    cat_query = category_query category
    cat_response = wikipedia.query cat_query
    # turn this into a list of articles
    articles_in_cat = cat_response.data['categorymembers']
    import_articles_in_category articles_in_cat
    article_ids = articles_in_cat.map { |article| article['pageid'] }
    import_latest_revision article_ids
    RevisionScoreImporter.update_revision_scores article_ids
    output = "title, average views, completeness, views/completeness\n"
    article_ids.each do |id|
      article = Article.find(id)
      title = article.title
      date = Date.today - 1.month
      average_views = Grok.average_views_for_article(title)
      completeness = article.revisions.last.wp10.to_f
      output += "#{title}, #{average_views}, #{completeness}, #{average_views / completeness}\n"
    end
    puts output
  end

  ##################
  # Helper methods #
  ##################
  def self.category_query(category)
    cat = 'Category:' + category
    cat_query = { list: 'categorymembers',
                  cmtitle: cat,
                  cmlimit: 50
                }
    cat_query
  end

  def self.revisions_query(article_ids)
    rev_query = { prop: 'revisions',
                  pageids: article_ids,
                  rvprop: 'userid|ids|timestamp'
                }
    rev_query
  end

  def self.import_articles_in_category(articles_in_cat)
    articles_to_import = articles_in_cat.map do |article|
      Article.new(
        id: article['pageid'],
        title: article['title'],
        namespace: article['ns'],
        deleted: false)
    end
    # import all the articles
    Article.import articles_to_import
  end

  def self.import_latest_revision(article_ids)
    rev_query = revisions_query(article_ids)
    rev_response = wikipedia.query rev_query
    latest_revisions = rev_response.data['pages']
    revisions_to_import = []
    article_ids.each do |id|
      rev_data = latest_revisions[id.to_s]['revisions'][0]
      new_article = (rev_data['parentid'] == 0)
      revisions_to_import << Revision.new(
                               id: rev_data['revid'],
                               article_id: id,
                               date: rev_data['timestamp'].to_datetime,
                               user_id: rev_data['userid'],
                               new_article: new_article)
    end
    Revision.import revisions_to_import
  end
  ##############
  # API Access #
  ##############
  class << self
    private

    def wikipedia
      language = ENV['wiki_language']
      url = "https://#{language}.wikipedia.org/w/api.php"
      @wikipedia = MediawikiApi::Client.new url
      @wikipedia
    end
  end
end
