require 'rails_helper'
require "#{Rails.root}/lib/article_status_manager"

describe ArticleStatusManager do
  describe '.update_article_status' do
    it 'should marked deleted articles as "deleted"' do
      course = create(:course,
                      end: '2016-12-31'.to_date)
      course.users << create(:user)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0)

      described_class.update_article_status
      expect(Article.find(1).deleted).to be true
    end

    it 'should update the ids of articles' do
      # en.wikipedia - article 100 does not exist
      create(:article,
             id: 100,
             mw_page_id: 100,
             title: 'Audi',
             namespace: 0)

      # es.wikipedia
      create(:wiki, id: 2, language: 'es', project: 'wikipedia')
      create(:article,
             id: 100000001,
             mw_page_id: 100000001,
             title: 'Audi',
             namespace: 0,
             wiki_id: 2)

      described_class.update_article_status

      expect(Article.find_by(title: 'Audi', wiki_id: 1).mw_page_id).to eq(848)
      expect(Article.find_by(title: 'Audi', wiki_id: 2).mw_page_id).to eq(4976786)
    end

    it 'should delete articles when id changed but new one already exists' do
      create(:article,
             id: 100,
             title: 'Audi',
             namespace: 0)
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 0)
      described_class.update_article_status
      expect(Article.find(100).deleted).to eq(true)
    end

    it 'should update the namespace are moved articles' do
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 2)

      described_class.update_article_status
      expect(Article.find_by(title: 'Audi').namespace).to eq(0)
    end

    it 'should handle cases of space vs. underscore' do
      # This page was first moved from a sandbox to "Yōji Sakate", then
      # moved again to "Yōji Sakate (playwright)". It ended up in our database
      # like this.
      create(:article,
             id: 46745170,
             # Currently this is a redirect to the other title.
             title: 'Yōji Sakate',
             namespace: 0)
      create(:article,
             id: 46364485,
             # Current title is "Yōji Sakate (playwright)".
             title: 'Yōji_Sakate',
             namespace: 0)
      described_class.update_article_status
    end

    it 'should handle case-variant titles' do
      article1 = create(:article,
                        id: 3914927,
                        title: 'Cyber-ethnography',
                        deleted: true,
                        namespace: 1)
      article2 = create(:article,
                        id: 46394760,
                        title: 'Cyber-Ethnography',
                        deleted: false,
                        namespace: 1)
      described_class.update_article_status
      expect(article1.id).to eq(3914927)
      expect(article2.id).to eq(46394760)
    end

    it 'should update the article_id for revisions when article_id changes' do
      create(:article,
             id: 2262715,
             mw_page_id: 2262715,
             title: 'Kostanay',
             namespace: 0)
      create(:revision,
             article_id: 2262715,
             mw_page_id: 2262715,
             mw_rev_id: 648515801)
      described_class.update_article_status

      new_article = Article.find_by(title: 'Kostanay')
      expect(new_article.mw_page_id).to eq(46349871)
      expect(new_article.revisions.count).to eq(1)
      expect(Revision.find_by(mw_rev_id: 648515801).article_id).to eq(new_article.id)
      expect(Revision.find_by(mw_rev_id: 648515801).mw_page_id).to eq(new_article.mw_page_id)
    end

    it 'does not delete articles by mistake if Replica is down' do
      create(:article,
             id: 848,
             title: 'Audi',
             namespace: 0)
      create(:article,
             id: 1,
             title: 'Noarticle',
             namespace: 0)
      allow_any_instance_of(Replica).to receive(:get_existing_articles_by_id).and_return(nil)
      described_class.update_article_status
      expect(Article.find(848).deleted).to eq(false)
      expect(Article.find(1).deleted).to eq(false)
    end
  end
end
