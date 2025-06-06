# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"
require "#{Rails.root}/lib/article_status_manager_timeslice"

describe ArticleStatusManagerTimeslice do
  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
  end

  # CHANGE THIS
  # For update_article_status_for_course, updated_at: 2.days.ago is used
  # because ArticleStatusManager updates articles updated more than 1 day ago
  # For update_status, it is not required, because it does not implement that logic

  let(:course) { create(:course, start: 1.year.ago, end: 1.year.from_now) }
  let(:user) { create(:user) }
  let(:wiki) { course.home_wiki }
  let!(:courses_user) { create(:courses_user, course:, user:) }

  describe '.update_article_status_for_course' do
    it 'marks deleted articles as "deleted"' do
      VCR.use_cassette 'article_status_manager/main' do
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:articles_course, course:, article_id: 1)
        create(:course_wiki_timeslice, course:, wiki:, start: 2.days.ago.beginning_of_day,
               end: 1.day.ago.beginning_of_day)
        create(:article_course_timeslice, course:, article_id: 1,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)

        described_class.update_article_status_for_course(course)
        expect(Article.find(1).deleted).to be true
        # It also deletes articles courses, timeslices and set them to reprocess
        expect(course.articles_courses.count).to eq(0)
        expect(course.article_course_timeslices.count).to eq(0)
        expect(course.course_wiki_timeslices.first.needs_update).to eq(true)
      end
    end

    it 'cleans associated Assignment records for deleted articles' do
      VCR.use_cassette 'article_status_manager/main' do
        article = create(:article,
                         id: 1,
                         mw_page_id: 1,
                         title: 'Noarticle',
                         namespace: 0,
                         updated_at: 2.days.ago)
        assignment = create(:assignment, article_title: 'Noarticle', article:, course:)
        expect(assignment.article_id).to eq(article.id)
        create(:article_course_timeslice, course:, article_id: 1,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
        described_class.update_article_status_for_course(course)
        expect(Article.find(1).deleted).to be true
        expect(assignment.reload.article_id).to eq(nil)
      end
    end

    it 'updates the mw_page_ids of articles' do
      VCR.use_cassette 'article_status_manager/mw_page_ids' do
        # en.wikipedia - article 100 does not exist
        create(:article,
               id: 100,
               mw_page_id: 100,
               title: 'Audi',
               namespace: 0,
               wiki_id: wiki.id,
               updated_at: 2.days.ago)
        create(:articles_course, course:, article_id: 100)
        create(:article_course_timeslice, course:, article_id: 100,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)

        # es.wikipedia - article 1 does not exist
        course.wikis << create(:wiki, id: 2, language: 'es', project: 'wikipedia')
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Audi',
               namespace: 0,
               wiki_id: 2,
               updated_at: 2.days.ago)
        create(:articles_course, course:, article_id: 1)
        create(:article_course_timeslice, course:, article_id: 1,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)

        described_class.update_article_status_for_course(course)

        expect(Article.find_by(title: 'Audi', wiki_id: wiki.id).mw_page_id).to eq(848)
        expect(Article.find_by(title: 'Audi', wiki_id: 2).mw_page_id).to eq(4976786)
      end
    end

    it 'deletes articles when id changed but new one already exists' do
      VCR.use_cassette 'article_status_manager/deleted_new_exists' do
        create(:article,
               id: 100,
               mw_page_id: 100,
               title: 'Audi',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:articles_course, course:, article_id: 100)
        create(:article_course_timeslice, course:, article_id: 100,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
        create(:course_wiki_timeslice, course:, wiki:, start: 2.days.ago.beginning_of_day,
              end: 1.day.ago.beginning_of_day)
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi',
               namespace: 0)
        create(:articles_course, course:, article_id: 848)
        create(:article_course_timeslice, course:, article_id: 848,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
        create(:course_wiki_timeslice, course:, wiki:, start: 3.days.ago.beginning_of_day,
              end: 2.days.ago.beginning_of_day)

        described_class.update_article_status_for_course(course)
        expect(Article.find_by(mw_page_id: 100).deleted).to eq(true)
        expect(Article.find_by(mw_page_id: 848).deleted).to eq(false)
        # It also deletes articles courses, timeslices and set them to reprocess
        expect(course.articles_courses.first.article_id).to eq(848)
        expect(course.article_course_timeslices.first.article_id).to eq(848)
        expect(course.course_wiki_timeslices.first.needs_update).to eq(true)
        expect(course.course_wiki_timeslices.second.needs_update).to eq(false)
      end
    end

    it 'cleans associated Assignment records when id changed but new one already exists' do
      VCR.use_cassette 'article_status_manager/deleted_new_exists' do
        article = create(:article,
                         id: 100,
                         mw_page_id: 100,
                         title: 'Audi',
                         namespace: 0,
                         updated_at: 2.days.ago)
        assignment = create(:assignment, article_title: 'Noarticle', article:, course:)
        create(:article_course_timeslice, course:, article_id: 100,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
        create(:article,
               id: 848,
               mw_page_id: 848,
               title: 'Audi',
               namespace: 0)
        create(:article_course_timeslice, course:, article_id: 848,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

        expect(assignment.article_id).to eq(article.id)
        described_class.update_article_status_for_course(course)
        expect(assignment.reload.article_id).to eq(nil)
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
        create(:article_course_timeslice, course:, article_id: 848,
               start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)

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
      create(:articles_course, course:, article_id: 53001516)
      create(:article_course_timeslice, course:, article_id: 53001516,
             start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
      create(:articles_course, course:, article_id: 53058287)
      create(:article_course_timeslice, course:, article_id: 53058287,
             start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
      # Create course wiki timeslices
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([course.home_wiki])

      VCR.use_cassette 'article_status_manager/undeletion_duplicate' do
        described_class.update_article_status_for_course(course)
      end
      expect(course.articles_courses.count).to eq(1)
      expect(course.article_course_timeslices.count).to eq(1)
      timeslice = course.course_wiki_timeslices.find_by(start: 3.days.ago.beginning_of_day)
      expect(timeslice.needs_update).to eq(true)
    end

    it 'handles undeleted articles' do
      create(:article,
             id: 53058287,
             mw_page_id: 66653200,
             title: 'Port_of_Spain_Gazette',
             deleted: true,
             updated_at: 2.days.ago)
      create(:article_course_timeslice, course:, article_id: 53058287,
             start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
      # Create course wiki timeslices
      TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([course.home_wiki])

      VCR.use_cassette 'article_status_manager/undeletion' do
        described_class.update_article_status_for_course(course)
      end
      expect(Article.find(53058287).deleted).to eq(false)
      timeslice = course.course_wiki_timeslices.find_by(start: 2.days.ago.beginning_of_day)
      expect(timeslice.needs_update).to eq(true)
    end

    context 'when a title is a unicode dump' do
      let(:zh_wiki) { create(:wiki, language: 'zh', project: 'wikipedia') }
      # https://zh.wikipedia.org/wiki/%E9%BB%83%F0%A8%A5%88%E7%91%A9
      let(:title) { CGI.escape('黃𨥈瑩') }
      let(:article) { create(:article, wiki: zh_wiki, title:, mw_page_id: 420741) }

      it 'skips updates when the title is a unicode dumps' do
        stub_wiki_validation
        VCR.use_cassette 'article_status_manager/unicode_dump' do
          described_class.new(course, zh_wiki).update_status([article])
          expect(Article.last.title).to eq(title)
        end
      end
    end

    it 'handles SQL errors gracefully' do
      expect_any_instance_of(Article).to receive(:update!).and_raise(ActiveRecord::StatementInvalid)
      VCR.use_cassette 'article_status_manager/errors' do
        article = create(:article, title: 'Selfeeee', mw_page_id: 38956275)
        described_class.new(course).update_status([article])
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
        create(:article_course_timeslice, course:, article_id: 46745170,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

        create(:article,
               id: 46364485,
               mw_page_id: 46364485,
               # Current title is "Yōji Sakate" as of 2016-07-06.
               title: 'Yōji_Sakate',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:article_course_timeslice, course:, article_id: 46364485,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

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
        create(:article_course_timeslice, course:, article_id: 3914927,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
        article2 = create(:article,
                          id: 46394760,
                          mw_page_id: 46394760,
                          title: 'Cyber-Ethnography',
                          deleted: false,
                          namespace: 1,
                          updated_at: 2.days.ago)
        create(:article_course_timeslice, course:, article_id: 46394760,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

        described_class.update_article_status_for_course(course)
        expect(article1.mw_page_id).to eq(3914927)
        expect(article2.mw_page_id).to eq(46394760)
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
        create(:article_course_timeslice, course:, article_id: 848,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:article_course_timeslice, course:, article_id: 1,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

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
        create(:article_course_timeslice, course:, article_id: 848,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
        create(:article,
               id: 1,
               mw_page_id: 1,
               title: 'Noarticle',
               namespace: 0,
               updated_at: 2.days.ago)
        create(:article_course_timeslice, course:, article_id: 1,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)

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
        create(:article_course_timeslice, course:, article_id: 50661367,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
        # Create course wiki timeslices
        TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records(
          [course.home_wiki]
        )
        described_class.update_article_status_for_course(course)
        expect(Article.find(50661367).deleted).to eq(false)
        timeslice = course.course_wiki_timeslices.find_by(start: 3.days.ago.beginning_of_day)
        expect(timeslice.needs_update).to eq(true)
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
        create(:article_course_timeslice, course:, article_id: 50661367,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
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
        create(:article_course_timeslice, course:, article_id: 50661367,
               start: 3.days.ago.beginning_of_day, end: 2.days.ago.beginning_of_day)
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
          described_class.new(course).update_status([article_to_update])
        end
        expect(article_to_update.reload.title).to eq('Homosexuality_in_modern_sports')
      end

      it 'marks timeslices as needs_update when mw_page_id collisions with an undeleted article' do
        deleted_article = create(:article, mw_page_id: 26788997, deleted: true)
        create(:articles_course, course:, article: deleted_article)
        create(:course_wiki_timeslice, course:, wiki:, start: 2.days.ago.beginning_of_day,
              end: 1.day.ago.beginning_of_day)
        expect(course.course_wiki_timeslices.first.needs_update).to eq(false)
        create(:article_course_timeslice, course:, article_id: deleted_article.id,
              start: 2.days.ago.beginning_of_day, end: 1.day.ago.beginning_of_day)
        VCR.use_cassette 'article_status_manager/duplicate_mw_page_ids' do
          described_class.new(course).update_status([deleted_article])
        end
        expect(course.course_wiki_timeslices.first.needs_update).to eq(true)
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
          described_class.new(course).update_status([article])
          expect(assignment.reload.article_title).to eq('Audi')
        end
      end
    end
  end
end
