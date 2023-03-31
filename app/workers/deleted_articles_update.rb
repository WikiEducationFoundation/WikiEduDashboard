# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/article_status_manager"
class DeletedArticlesUpdate
  def initialize
    last_run = Setting.find_or_create_by(key: 'deleted_articles')
    @last_timestamp = last_run.value['timestamp'] || 1.day.ago.to_i
    update_deleted_status

    last_run.value['timestamp'] = Time.now.to_i
    last_run.save!
  end

  private

  def update_deleted_status
    Wiki.all.each do |wiki|
      articles = Article.where(wiki:)
      to_delete, to_restore = ids_for_wiki(wiki)
      articles.where(mw_page_id: to_delete).update_all(deleted: true)
      articles.where(mw_page_id: to_restore).update_all(deleted: false)
      ArticleStatusManager.update_article_ids(to_delete, wiki)
    end
  end

  def ids_for_wiki(wiki)
    wiki_api = WikiApi.new(wiki)

    @deleted_articles_ids = {}
    @restored_articles_ids = {}

    wiki_api.deleted_logs(@last_timestamp)['logevents'].each do |log|
      @deleted_articles_ids[log['logpage']] = Time.iso8601(log['timestamp'])
    end
    wiki_api.restored_logs(@last_timestamp)['logevents'].each do |log|
      @restored_articles_ids[log['logpage']] = Time.iso8601(log['timestamp'])
    end

    [articles_to_delete, articles_to_restore]
  end

  def articles_to_delete
    to_delete = []

    @deleted_articles_ids.each do |page_id, timestamp|
      if @restored_articles_ids[page_id].nil? || @restored_articles_ids[page_id] < timestamp
        to_delete << page_id
      end
    end
    to_delete
  end

  def articles_to_restore
    to_restore = []

    @restored_articles_ids.each do |page_id, timestamp|
      if @deleted_articles_ids[page_id].nil? || @deleted_articles_ids[page_id] < timestamp
        to_restore << page_id
      end
    end
    to_restore
  end
end
