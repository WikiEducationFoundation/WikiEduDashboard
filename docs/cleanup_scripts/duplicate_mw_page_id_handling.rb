require Rails.root.join('lib/article_status_manager')
require Rails.root.join('lib/duplicate_article_deleter')

class DuplicatePageIdHandler
  def self.process_all
    duplicate_counts = Article.where(deleted: false).group(:mw_page_id, :wiki_id).having('count(*) > 1').count
    count = duplicate_counts.count
    i = 0
    duplicate_counts.keys.each do |key|
      i += 1
      puts "Processing #{i}/#{count}"
      wiki = Wiki.find(key[1])
      mw_page_id = key[0]
      new(mw_page_id, wiki)
    end
  end

  def initialize(mw_page_id, wiki)
    arts = Article.where(mw_page_id: mw_page_id, wiki_id: wiki.id, deleted: false)
    arts.each do |art|
      puts art.title
      ArticleStatusManager.new(wiki).update_status([art])
    end
    arts = Article.where(mw_page_id: mw_page_id, wiki_id: wiki.id, deleted: false)
    puts 'processing dupes'
    DuplicateArticleDeleter.new(wiki).resolve_duplicates(arts)
  end
end

Assignment.where.not(article_id: nil).find_each do |ass|
  next unless ass.article.nil?
  ass.update(article_id: nil)
end
