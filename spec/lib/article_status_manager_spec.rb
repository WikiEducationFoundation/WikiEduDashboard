# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_status_manager"

describe ArticleStatusManager do
  before { stub_wiki_validation }

  # For update_article_status_for_course, updated_at: 2.days.ago is used
  # because ArticleStatusManager updates articles updated more than 1 day ago
  # For update_status, it is not required, because it does not implement that logic

  let(:course) { create(:course, start: 1.year.ago, end: 1.year.from_now) }
  let(:user) { create(:user) }
  let!(:courses_user) { create(:courses_user, course:, user:) }
  let(:update_service) { instance_double('UpdateService') }

  describe '.update_article_status_for_course' do
    it 'logs unexpected errors with the update_service passed' do
      # Simulate an unexpected error
      allow_any_instance_of(Course).to receive(:pages_edited)
        .and_raise(StandardError, 'Unexpected error occurred')

      expect_any_instance_of(described_class).to receive(:log_error).with(
        instance_of(StandardError),
        update_service:,
        sentry_extra: { course_id: course.id, wiki_id: anything }
      ).once

      # Call the method to trigger the error
      described_class.update_article_status_for_course(course, update_service:)
    end

    it 'marks deleted articles as "deleted"' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 1, user:)

        described_class.update_article_status_for_course(course)
        expect(Article.find(1).deleted).to be true
      end
    end

    it 'updates the mw_page_ids of articles' do
      # pending 'This sometimes fails for unknown reasons.'
      VCR.use_cassette 'article_status_manager/mw_page_ids' do
        # en.wikipedia - article 100 does not exist
        create(:article,
               id: 100,
               mw_page_id: 100,
               title: 'Audi',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 100, user:)

        # es.wikipedia
        course.wikis << create(:wiki, id: 2, language: 'es', project: 'wikipedia')
        create(:article,
               id: 10000001,
               mw_page_id: 10000001,
               title: 'Audi',
               namespace: 0,
               wiki_id: 2,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 10000001, user:)

        described_class.update_article_status_for_course(course)

        expect(Article.find_by(title: 'Audi', wiki_id: 1).mw_page_id).to eq(848)
        expect(Article.find_by(title: 'Audi', wiki_id: 2).mw_page_id).to eq(4976786)
      end
      # pass_pending_spec
    end

    it 'deletes articles when id changed but new one already exists' do
      VCR.use_cassette 'article_status_manager/deleted_new_exists' do
        create(:article,
               id: 100,
               mw_page_id: 100,
               title: 'Audi',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 100, user:)
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi',
               namespace: 0)
        create(:revision, date: 1.day.ago, article_id: 848, user:)

        described_class.update_article_status_for_course(course)
        expect(Article.find_by(mw_page_id: 100).deleted).to eq(true)
      end
    end

    it 'updates the namespace and titles when articles are moved' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi_Cars', # 'Audi' is the actual title
               namespace: 2,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 848, user:)

        described_class.update_article_status_for_course(course)
        expect(Article.find(848).namespace).to eq(0)
        expect(Article.find(848).title).to eq('Audi')
      end
    end

    it 'handles cases with deleted and nondeleted copies of an article' do
      create(:article,
             id: 53001516,
             mw_page_id: 66653200,
             title: 'Port_of_Spain_Gazette',
             updated_at: 2.days.ago)
      create(:article,
             id: 53058287,
             mw_page_id: 66653200,
             title: 'Port_of_Spain_Gazette',
             deleted: true,
             updated_at: 2.days.ago)
      create(:revision, date: 1.day.ago, article_id: 53001516, user:)
      create(:revision, date: 1.day.ago, article_id: 53058287, user:)

      VCR.use_cassette 'article_status_manager/undeletion_duplicate' do
        described_class.update_article_status_for_course(course)
      end
      expect(Article.find(53001516).revisions.count).to eq(2)
    end

    it 'handles undeleted articles' do
      create(:article,
             id: 53058287,
             mw_page_id: 66653200,
             title: 'Port_of_Spain_Gazette',
             deleted: true,
             updated_at: 2.days.ago)
      create(:revision, date: 1.day.ago, article_id: 53058287, user:)

      VCR.use_cassette 'article_status_manager/undeletion' do
        described_class.update_article_status_for_course(course)
      end
      expect(Article.find(53058287).deleted).to eq(false)
    end

    context 'when a title is a unicode dump' do
      let(:zh_wiki) { create(:wiki, language: 'zh', project: 'wikipedia') }
      # https://zh.wikipedia.org/wiki/%E9%BB%83%F0%A8%A5%88%E7%91%A9
      let(:title) { CGI.escape('黃𨥈瑩') }
      let(:article) { create(:article, wiki: zh_wiki, title:, mw_page_id: 420741) }

      it 'skips updates when the title is a unicode dumps' do
        stub_wiki_validation
        VCR.use_cassette 'article_status_manager/unicode_dump' do
          described_class.new(zh_wiki).update_status([article])
          expect(Article.last.title).to eq(title)
        end
      end
    end

    it 'handles SQL errors gracefully' do
      expect_any_instance_of(Article).to receive(:update!).and_raise(ActiveRecord::StatementInvalid)
      VCR.use_cassette 'article_status_manager/errors' do
        article = create(:article, title: 'Selfeeee', mw_page_id: 38956275)
        described_class.new.update_status([article])
      end
    end

    it 'handles cases of space vs. underscore' do
      VCR.use_cassette 'article_status_manager/main' do
        # This page was first moved from a sandbox to "Yōji Sakate", then
        # moved again to "Yōji Sakate (playwright)". It ended up in our database
        # like this.
        create(:article,
               id: 46745170,
               mw_page_id: 46745170,
               # Currently this is a redirect to the other title.
               title: 'Yōji Sakate',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 46745170, user:)

        create(:article,
               id: 46364485,
               mw_page_id: 46364485,
               # Current title is "Yōji Sakate" as of 2016-07-06.
               title: 'Yōji_Sakate',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 46364485, user:)

        described_class.update_article_status_for_course(course)
      end
    end

    it 'handles case-variant titles' do
      VCR.use_cassette 'article_status_manager/main' do
        article1 = create(:article,
                          id: 3914927,
                          mw_page_id: 3914927,
                          title: 'Cyber-ethnography',
                          deleted: true,
                          namespace: 1,
                          updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 3914927, user:)
        article2 = create(:article,
                          id: 46394760,
                          mw_page_id: 46394760,
                          title: 'Cyber-Ethnography',
                          deleted: false,
                          namespace: 1,
                          updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 46394760, user:)

        described_class.update_article_status_for_course(course)
        expect(article1.mw_page_id).to eq(3914927)
        expect(article2.mw_page_id).to eq(46394760)
      end
    end

    it 'updates the mw_rev_id for revisions when article record changes' do
      VCR.use_cassette 'article_status_manager/update_for_revisions' do
        create(:article,
               id: 2262715,
               mw_page_id: 2262715,
               title: 'Kostanay',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision,
               date: 1.day.ago,
               user:,
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
    end

    it 'does not delete articles by mistake if Replica is down' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 848, user:)
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 1, user:)

        allow_any_instance_of(Replica).to receive(:get_existing_articles_by_id).and_return(nil)
        described_class.update_article_status_for_course(course)
        expect(Article.find(848).deleted).to eq(false)
        expect(Article.find(1).deleted).to eq(false)
      end
    end

    it 'does not delete articles by mistake if Replica goes right before trying to fetch titles' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 848, user:)
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 1, user:)

        allow_any_instance_of(Replica).to receive(:post_existing_articles_by_title).and_return(nil)
        described_class.update_article_status_for_course(course)
        expect(Article.find(848).deleted).to eq(false)
        expect(Article.find(1).deleted).to eq(false)
      end
    end

    it 'marks an undeleted article as not deleted' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 50661367,
               mw_page_id: 52228477,
               title: 'Antiochis_of_Tlos',
               namespace: 0,
               deleted: true,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 50661367, user:)
        described_class.update_article_status_for_course(course)
        expect(Article.find(50661367).deleted).to eq(false)
      end
    end

    it 'updates if article updated more than 1 day ago' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 50661367,
               mw_page_id: 52228477,
               title: 'Antiochis_of_Tlos',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:revision, date: 1.day.ago, article_id: 50661367, user:)
        described_class.update_article_status_for_course(course)
        expect(Article.find(50661367).updated_at > 30.seconds.ago).to eq(true)
      end
    end

    it 'does not update if article updated less than 1 day ago' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 50661367,
               mw_page_id: 52228477,
               title: 'Antiochis_of_Tlos',
               namespace: 0,
               updated_at: 12.hours.ago)
        create(:revision, date: 1.day.ago, article_id: 50661367, user:)
        described_class.update_article_status_for_course(course)
        expect(Article.find(50661367).updated_at <= 12.hours.ago).to eq(true)
      end
    end
  end

  describe '#update_status' do
    context 'when passed a single article' do
      let!(:first_article) do
        create(:article,
               title: 'Homosexuality_in_modern_sports',
               mw_page_id: 26788997,
               namespace: 0)
      end

      let!(:article_to_update) do
        build(:article,
              title: 'Homosexuality_in_Modern_Sports',
              mw_page_id: 26788997,
              deleted: true,
              namespace: 0)
        Article.last
      end

      it 'updates that article and not another with the same mw_page_id' do
        VCR.use_cassette 'article_status_manager/duplicate_mw_page_ids' do
          described_class.new.update_status([article_to_update])
        end
        expect(article_to_update.reload.title).to eq('Homosexuality_in_modern_sports')
      end

      it 'moves revisions after mw_page_id collisions with an undeleted article' do
        deleted_article = create(:article, mw_page_id: 26788997, deleted: true)
        create(:revision, article: deleted_article)
        VCR.use_cassette 'article_status_manager/duplicate_mw_page_ids' do
          described_class.new.update_status([deleted_article])
        end
        expect(deleted_article.revisions.count).to eq(0)
      end

      it 'updates associated Assignment records with the new title' do
        VCR.use_cassette 'article_status_manager/assignments' do
          article = create(:article, mw_page_id: 848,
                           title: 'Audi_Cars', # 'Audi' is the actual title
                           namespace: 2,
                           updated_at: 2.days.ago)
          assignment = create(:assignment, article_title: 'Audi_Cars',
                                           article:,
                                           course:)
          described_class.new.update_status([article])
          expect(assignment.reload.article_title).to eq('Audi')
        end
      end
    end
  end
end
