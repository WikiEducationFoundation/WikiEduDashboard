# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_revision_updater"

describe CourseRevisionUpdater do
  describe '#fetch_full_data_for_course_wiki' do
    let(:user) { create(:user, username: 'Tedholtby') }
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:start_date) { '20160320000000' }
    let(:end_date) { '20160331235959' }

    context 'for regular courses' do
      let(:course) { create(:course, start: '2016-03-20', end: '2016-03-31') }
      let(:instance_class) { described_class.new(course) }
      let!(:courses_user) do
        create(:courses_user, course:,
                            user:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      before do
        create(:course_wiki_timeslice, course:, wiki:, start: start_date,
        end: end_date.to_datetime + 1.day)
      end

      it 'fetches all the revisions with scores if only_new is false' do
        VCR.use_cassette 'course_revision_updater' do
          revision_data = instance_class.fetch_full_data_for_course_wiki(wiki, start_date, end_date)
          expect(revision_data[wiki][:new_data]).to eq(true)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # fetched scores
          expect(revisions.last.features).to eq({ 'num_ref' => 19 })
          expect(revisions.last.features_previous).to eq({ 'num_ref' => 18 })
          expect(revisions.last.wp10.to_f).to be_within(0.01).of(47.03)
          expect(revisions.last.wp10_previous.to_f).to be_within(0.01).of(46.94)
        end
      end

      it 'fetches all the revisions with scoress if only_new is true and new revisions' do
        VCR.use_cassette 'course_revision_updater' do
          revision_data = instance_class.fetch_full_data_for_course_wiki(wiki, start_date, end_date,
                                                                         only_new: true)
          expect(revision_data[wiki][:new_data]).to eq(true)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # fetched scores
          expect(revisions.last.features).to eq({ 'num_ref' => 19 })
          expect(revisions.last.features_previous).to eq({ 'num_ref' => 18 })
          expect(revisions.last.wp10.to_f).to be_within(0.01).of(47.03)
          expect(revisions.last.wp10_previous.to_f).to be_within(0.01).of(46.94)
        end
      end

      it 'does not fetch scores if only_new is true and no new revisions' do
        # complete the timeslice
        last_mw_rev_datetime = '2016-03-31 19:50:54'.to_datetime
        course.course_wiki_timeslices.update(revision_count: 3,
                                             last_mw_rev_datetime:)
        VCR.use_cassette 'course_revision_updater' do
          revision_data = instance_class.fetch_full_data_for_course_wiki(wiki, start_date, end_date,
                                                                         only_new: true)
          expect(revision_data[wiki][:new_data]).to eq(false)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # no fetched scores
          expect(revisions.last.features).to be_empty
          expect(revisions.last.features_previous).to be_empty
          expect(revisions.last.wp10).to be_nil
          expect(revisions.last.wp10_previous).to be_nil
        end
      end

      it 'does not fail when fetching data for partial timeslice' do
        # complete the timeslice
        last_mw_rev_datetime = '2016-03-31 19:50:54'.to_datetime
        course.course_wiki_timeslices.update(revision_count: 3,
                                             last_mw_rev_datetime:)
        VCR.use_cassette 'course_revision_updater' do
          expect(Sentry).not_to receive(:capture_message)
          revision_data = instance_class.fetch_full_data_for_course_wiki(wiki, '20160331092530',
                                                                         '20160331225055',
                                                                         only_new: true)
          expect(revision_data[wiki][:new_data]).to eq(false)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # no fetched scores
          expect(revisions.last.features).to be_empty
          expect(revisions.last.features_previous).to be_empty
          expect(revisions.last.wp10).to be_nil
          expect(revisions.last.wp10_previous).to be_nil
        end
      end
    end

    context 'for ArticleScopedCourse' do
      let(:scoped_course) { create(:article_scoped_program) }
      let(:scoped_instance_class) { described_class.new(scoped_course) }
      let!(:courses_user) do
        create(:courses_user, course: scoped_course,
                            user:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'skips import if no tracked articles' do
        expect(scoped_instance_class).not_to receive(:fetch_data)
        response = scoped_instance_class.fetch_full_data_for_course_wiki(wiki, start_date, end_date)
        expect(response[wiki][:revisions]).to eq([])
      end
    end
  end

  describe '#fetch_revisions_for_course_wiki' do
    let(:user) { create(:user, username: 'Tedholtby') }
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:start_date) { '20160320000000' }
    let(:end_date) { '20160331235959' }

    context 'for regular courses' do
      let(:course) { create(:course, start: '2016-03-20', end: '2016-03-31') }
      let(:instance_class) { described_class.new(course) }
      let!(:courses_user) do
        create(:courses_user, course:,
                            user:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      before do
        create(:course_wiki_timeslice, course:, wiki:, start: start_date,
        end: end_date.to_datetime + 1.day)
      end

      it 'fetches all the revisions without scores' do
        VCR.use_cassette 'course_revision_updater' do
          revision_data = instance_class.fetch_revisions_for_course_wiki(wiki, start_date, end_date)
          expect(revision_data[wiki][:new_data]).to eq(false)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # no fetched scores
          expect(revisions.last.features).to be_empty
          expect(revisions.last.features_previous).to be_empty
          expect(revisions.last.wp10).to be_nil
          expect(revisions.last.wp10_previous).to be_nil
        end
      end

      it 'does not fail when fetching data for partial timeslice' do
        # complete the timeslice
        last_mw_rev_datetime = '2016-03-31 19:50:54'.to_datetime
        course.course_wiki_timeslices.update(revision_count: 3,
                                             last_mw_rev_datetime:)
        VCR.use_cassette 'course_revision_updater' do
          expect(Sentry).not_to receive(:capture_message)
          revision_data = instance_class.fetch_revisions_for_course_wiki(wiki, '20160331092530',
                                                                         '20160331225055')
          expect(revision_data[wiki][:new_data]).to eq(false)
          revisions = revision_data.values.flat_map { |data| data[:revisions] }.flatten
          expect(revisions.count).to eq(3)

          expected_article = Article.find_by(wiki_id: 1,
                                             title: '1978_Revelation_on_Priesthood',
                                             mw_page_id: 15124285,
                                             namespace: 0)

          expect(revisions.last.mw_rev_id).to eq(712907095)
          expect(revisions.last.user_id).to eq(user.id)
          expect(revisions.last.wiki_id).to eq(1)
          expect(revisions.last.mw_page_id).to eq(15124285)
          expect(revisions.last.characters).to eq(579)
          expect(revisions.last.article_id).to eq(expected_article.id)
          # no fetched scores
          expect(revisions.last.features).to be_empty
          expect(revisions.last.features_previous).to be_empty
          expect(revisions.last.wp10).to be_nil
          expect(revisions.last.wp10_previous).to be_nil
        end
      end
    end

    context 'for ArticleScopedCourse' do
      let(:scoped_course) { create(:article_scoped_program) }
      let(:scoped_instance_class) { described_class.new(scoped_course) }
      let!(:courses_user) do
        create(:courses_user, course: scoped_course,
                            user:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'skips import if no tracked articles' do
        expect(scoped_instance_class).not_to receive(:fetch_data)
        response = scoped_instance_class.fetch_revisions_for_course_wiki(wiki, start_date, end_date)
        expect(response[wiki][:revisions]).to eq([])
      end
    end
  end
end
