require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/grok"
require "#{Rails.root}/lib/wiki"

#= Imports articles for a category, along with view data and revision scores
class CategoryImporter
  ################
  # Entry points #
  ################
  def self.import_category(category, depth=0, cumulative_article_ids=nil)
    cumulative_article_ids ||= []
    article_ids = article_ids_for_category(category)
    ArticleImporter.import_articles article_ids
    import_latest_revision article_ids
    import_scores_for_latest_revision article_ids
    update_average_views article_ids
    cumulative_article_ids += article_ids
    if depth > 0
      depth = depth - 1
      subcats = subcategories_of(category)
      subcats.each do |subcat|
        import_category(subcat, depth)
        cumulative_article_ids += article_ids_for_category(subcat)
      end
    end
    views_and_scores_output cumulative_article_ids
  end

  ##################
  # Output methods #
  ##################
  def self.views_and_scores_output(article_ids)
    output = "title, average views, completeness, views/completeness\n"
    article_ids.each do |id|
      article = Article.find(id)
      title = article.title
      completeness = article.revisions.last.wp10.to_f
      average_views = article.average_views
      output += "#{title}, #{average_views}, #{completeness}, #{average_views / completeness}\n"
    end
    puts output
  end

  ##################
  # Helper methods #
  ##################
  def self.article_ids_for_category(category)
    article_ids = []

    cat_query = category_query category
    continue = true
    until continue.nil?
      cat_response = Wiki.query cat_query
      article_data = cat_response.data['categorymembers']
      article_data.each do |article|
        article_ids << article['pageid']
      end
      continue = cat_response['continue']
      cat_query['cmcontinue'] = continue['cmcontinue'] if continue
    end

    article_ids
  end

  def self.subcategories_of(category)
    subcats = []
    subcat_query = category_query(category, 14) # 14 is the Category namespace

    continue = true
    until continue.nil?
      subcat_response = Wiki.query subcat_query
      subcat_data = subcat_response.data['categorymembers']
      subcat_data.each do |subcat|
        subcats << subcat['title']
      end
      continue = subcat_response['continue']
      subcat_query['cmcontinue'] = continue['cmcontinue'] if continue
    end
    subcats
  end

  def self.category_query(category, namespace=0)
    cat_query = { list: 'categorymembers',
                  cmtitle: category,
                  cmlimit: 500,
                  cmnamespace: namespace, # mainspace articles by default
                  continue: ''
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

  def self.import_latest_revision(article_ids)
    latest_revisions = get_revision_data article_ids
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

  def self.get_revision_data(article_ids)
    latest_revisions = {}
    article_ids.each_slice(50) do |fifty_ids|
      rev_query = revisions_query(fifty_ids)
      rev_response = Wiki.query rev_query
      latest_revisions.merge! rev_response.data['pages']
    end
    latest_revisions
  end

  def self.import_scores_for_latest_revision(article_ids)
    revisions_to_update = []
    article_ids.each do |id|
      next unless Article.exists?(id)
      revision = Article.find(id).revisions.last
      revisions_to_update << revision if revision.wp10.nil?
    end
    RevisionScoreImporter.update_revision_scores revisions_to_update
  end

  def self.update_average_views(article_ids)
    articles = Article.where(id: article_ids)
    articles.each do |article|
      next unless article.average_views.nil? || article.average_views_updated_at < 1.month.ago
      article.average_views = Grok.average_views_for_article(article.title)
      article.average_views_updated_at = Date.today
      article.save
    end
  end
end
