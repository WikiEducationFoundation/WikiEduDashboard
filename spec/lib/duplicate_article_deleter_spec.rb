# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/duplicate_article_deleter"

describe DuplicateArticleDeleter do
  describe '.resolve_duplicates' do
    let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:deleted_article) do
      create(:article, title: 'Columbian_exchange',
                       namespace: 0,
                       mw_page_id: 5589352,
                       created_at: '2017-08-23',
                       wiki: en_wiki,
                       deleted: true)
    end
    let(:extant_article) do
      create(:article, title: 'Columbian_exchange',
                       namespace: 0,
                       mw_page_id: 622746,
                       created_at: '2017-12-08',
                       wiki: en_wiki,
                       deleted: false)
    end
    let(:duplicate_deleted_article) do
      create(:article, title: 'Columbian_exchange',
                       namespace: 0,
                       mw_page_id: 622746,
                       created_at: '2017-12-08',
                       wiki: en_wiki,
                       deleted: true)
    end

    it 'marks oldest one deleted when there are two ids for one page' do
      new_article = create(:article,
                           id: 2262715,
                           title: 'Kostanay',
                           namespace: 0,
                           created_at: 1.day.from_now)
      duplicate_article = create(:article,
                                 id: 46349871,
                                 title: 'Kostanay',
                                 namespace: 0,
                                 created_at: 1.day.ago)
      described_class.new.resolve_duplicates([new_article])
      deleted = Article.where(
        title: 'Kostanay',
        namespace: 0,
        deleted: true
      )

      expect(deleted.count).to eq(1)
      expect(deleted.first.id).to eq(duplicate_article.id)
    end

    it 'does not mark any deleted when articles different in title case' do
      first = create(:article,
                     id: 123,
                     title: 'Communicative_language_teaching',
                     namespace: 0)
      second = create(:article,
                      id: 456,
                      title: 'Communicative_Language_Teaching',
                      namespace: 0)
      described_class.new.resolve_duplicates([first, second])
      expect(first.reload.deleted).to eq(false)
      expect(second.reload.deleted).to eq(false)
    end

    it 'marks does not end up leaving both articles deleted' do
      described_class.new.resolve_duplicates([deleted_article, extant_article])
      expect(deleted_article.reload.deleted).to eq(true)
      expect(extant_article.reload.deleted).to eq(false)
    end

    it 'does not error if all articles are already deleted' do
      described_class.new.resolve_duplicates([deleted_article, duplicate_deleted_article])
      expect(deleted_article.reload.deleted).to eq(true)
      expect(duplicate_deleted_article.reload.deleted).to eq(true)
    end
  end
end
