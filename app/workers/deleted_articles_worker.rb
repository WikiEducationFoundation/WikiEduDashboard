# frozen_string_literal: true
class DeletedArticlesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    last_run = Setting.find_or_create_by(key: 'deleted_articles')
    last_timestamp = last_run.value['timestamp'] || 1.week.ago.to_i
    Wiki.all.each do |wiki|
      articles = Article.where(wiki:, deleted: false)
      wiki_api = WikiApi.new(wiki)
      deleted_articles_ids = {}
      restored_articles_ids = {}
      wiki_api.deleted_logs(last_timestamp)['logevents'].each do |log|
        deleted_articles_ids[log['logpage']] = Time.iso8601(log['timestamp'])
      end
      wiki_api.restored_logs(last_timestamp)['logevents'].each do |log|
        restored_articles_ids[log['logpage']] = Time.iso8601(log['timestamp'])
      end

      to_delete = []
      to_restore = []

      deleted_articles_ids.each do |page_id, timestamp|
        if restored_articles_ids[page_id].nil? || restored_articles_ids[page_id] < timestamp
          to_delete << page_id
        end
      end

      restored_articles_ids.each do |page_id, timestamp|
        if deleted_articles_ids[page_id].nil? || deleted_articles_ids[page_id] < timestamp
          to_restore << page_id
        end
      end

      articles.where(mw_page_id: to_delete).update_all(deleted: true)
      articles.where(mw_page_id: to_restore).update_all(deleted: false)
    end
    last_run.value['timestamp'] = Time.now.to_i
    last_run.save!
  end
end
