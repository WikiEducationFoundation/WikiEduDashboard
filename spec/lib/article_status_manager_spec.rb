# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_status_manager"

describe ArticleStatusManager do
  before { stub_wiki_validation }
  let(:course) { create(:course, start: 1.year.ago, end: 1.year.from_now) }
  let(:user) { create(:user) }
  let!(:courses_user) { create(:courses_user, course: course, user: user) }

  describe '.update_article_status' do
    it 'runs without error' do
      described_class.update_article_status
    end
  end

  describe '.update_article_status_for_course' do
    it 'marks deleted articles as "deleted"' do
      create(:article,
             id: 1,
             mw_page_id: 1,
             title: 'Noarticle',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 1, user: user)

      described_class.update_article_status_for_course(course)
      expect(Article.find(1).deleted).to be true
    end

    it 'updates the mw_page_ids of articles' do
      # en.wikipedia - article 100 does not exist
      create(:article,
             id: 100,
             mw_page_id: 100,
             title: 'Audi',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 100, user: user)

      # es.wikipedia
      create(:wiki, id: 2, language: 'es', project: 'wikipedia')
      create(:article,
             id: 100000001,
             mw_page_id: 100000001,
             title: 'Audi',
             namespace: 0,
             wiki_id: 2)
      create(:revision, date: 1.day.ago, article_id: 100000001, user: user)

      described_class.update_article_status_for_course(course)

      expect(Article.find_by(title: 'Audi', wiki_id: 1).mw_page_id).to eq(848)
      expect(Article.find_by(title: 'Audi', wiki_id: 2).mw_page_id).to eq(4976786)
    end

    it 'deletes articles when id changed but new one already exists' do
      create(:article,
             id: 100,
             mw_page_id: 100,
             title: 'Audi',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 100, user: user)
      create(:article,
             id: 848,
             mw_page_id: 848,
             title: 'Audi',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 848, user: user)

      described_class.update_article_status_for_course(course)
      expect(Article.find_by(mw_page_id: 100).deleted).to eq(true)
    end

    it 'updates the namespace and titles when articles are moved' do
      create(:article,
             id: 848,
             mw_page_id: 848,
             title: 'Audi_Cars', # 'Audi' is the actual title
             namespace: 2)
      create(:revision, date: 1.day.ago, article_id: 848, user: user)

      described_class.update_article_status_for_course(course)
      expect(Article.find(848).namespace).to eq(0)
      expect(Article.find(848).title).to eq('Audi')
    end

    it 'handles cases of space vs. underscore' do
      # This page was first moved from a sandbox to "Yōji Sakate", then
      # moved again to "Yōji Sakate (playwright)". It ended up in our database
      # like this.
      create(:article,
             id: 46745170,
             mw_page_id: 46745170,
             # Currently this is a redirect to the other title.
             title: 'Yōji Sakate',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 46745170, user: user)

      create(:article,
             id: 46364485,
             mw_page_id: 46364485,
             # Current title is "Yōji Sakate" as of 2016-07-06.
             title: 'Yōji_Sakate',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 46364485, user: user)

      described_class.update_article_status_for_course(course)
    end

    it 'handles case-variant titles' do
      article1 = create(:article,
                        id: 3914927,
                        mw_page_id: 3914927,
                        title: 'Cyber-ethnography',
                        deleted: true,
                        namespace: 1)
      create(:revision, date: 1.day.ago, article_id: 3914927, user: user)
      article2 = create(:article,
                        id: 46394760,
                        mw_page_id: 46394760,
                        title: 'Cyber-Ethnography',
                        deleted: false,
                        namespace: 1)
      create(:revision, date: 1.day.ago, article_id: 46394760, user: user)

      described_class.update_article_status_for_course(course)
      expect(article1.id).to eq(3914927)
      expect(article2.id).to eq(46394760)
    end

    it 'updates the mw_rev_id for revisions when article record changes' do
      create(:article,
             id: 2262715,
             mw_page_id: 2262715,
             title: 'Kostanay',
             namespace: 0)
      create(:revision,
             date: 1.day.ago,
             user: user,
             article_id: 2262715,
             mw_page_id: 2262715,
             mw_rev_id: 648515801)
      described_class.update_article_status_for_course(course)

      new_article = Article.find_by(title: 'Kostanay')
      expect(new_article.mw_page_id).to eq(46349871)
      expect(new_article.revisions.count).to eq(1)
      expect(Revision.find_by(mw_rev_id: 648515801).article_id).to eq(new_article.id)
      expect(Revision.find_by(mw_rev_id: 648515801).mw_page_id).to eq(new_article.mw_page_id)
    end

    it 'does not delete articles by mistake if Replica is down' do
      create(:article,
             id: 848,
             mw_page_id: 848,
             title: 'Audi',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 848, user: user)
      create(:article,
             id: 1,
             mw_page_id: 1,
             title: 'Noarticle',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 1, user: user)

      allow_any_instance_of(Replica).to receive(:get_existing_articles_by_id).and_return(nil)
      described_class.update_article_status_for_course(course)
      expect(Article.find(848).deleted).to eq(false)
      expect(Article.find(1).deleted).to eq(false)
    end

    it 'does not delete articles by mistake if Replica goes right before trying to fetch titles' do
      create(:article,
             id: 848,
             mw_page_id: 848,
             title: 'Audi',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 848, user: user)
      create(:article,
             id: 1,
             mw_page_id: 1,
             title: 'Noarticle',
             namespace: 0)
      create(:revision, date: 1.day.ago, article_id: 1, user: user)

      allow_any_instance_of(Replica).to receive(:get_existing_articles_by_title).and_return(nil)
      described_class.update_article_status_for_course(course)
      expect(Article.find(848).deleted).to eq(false)
      expect(Article.find(1).deleted).to eq(false)
    end

    it 'marks an undeleted article as not deleted' do
      create(:article,
             id: 50661367,
             mw_page_id: 52228477,
             title: 'Antiochis_of_Tlos',
             namespace: 0,
             deleted: true)
      create(:revision, date: 1.day.ago, article_id: 50661367, user: user)
      described_class.update_article_status_for_course(course)
      expect(Article.find(50661367).deleted).to eq(false)
    end
  end
end
