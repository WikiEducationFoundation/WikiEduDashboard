# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_revision_updater"

describe CourseRevisionUpdater do
  describe 'imported revisions and articles' do
    let(:course) { create(:course, id: 1, start: '2016-03-20', end: '2016-03-31') }
    let(:user) { create(:user, username: 'Tedholtby') }
    let(:courses_user) do
      create(:courses_user, course_id: 1, user_id: user.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    let(:revision_import) do
      course && user && courses_user
      Course.all.each { |course| described_class.import_revisions(course, all_time: true) }
    end

    it 'includes the correct article and revision data' do
      VCR.use_cassette 'course_revision_updater' do
        revision_import
        expected_article = Article.find_by(wiki_id: 1,
                                           title: '1978_Revelation_on_Priesthood',
                                           mw_page_id: 15124285,
                                           namespace: 0)

        expected_revision = Revision.find_by(mw_rev_id: 712907095,
                                             user_id: user.id,
                                             wiki_id: 1,
                                             mw_page_id: 15124285,
                                             characters: 579,
                                             article_id: expected_article.id)
        expect(expected_revision).to be_a(Revision)
      end
    end

    it 'updates article title if it does not match existing article record' do
      VCR.use_cassette 'course_revision_updater' do
        create(:article, id: 15124285, mw_page_id: 15124285, wiki_id: 1, title: 'foo')

        revision_import

        expect(Article.find_by(mw_page_id: 15124285).title).to eq('1978_Revelation_on_Priesthood')
        expect(Article.where(mw_page_id: 15124285).count).to eq(1)
      end
    end
  end

  describe '.import_revisions' do
    it 'includes revisions on the final day of a course up to the end time' do
      VCR.use_cassette 'course_revision_updater' do
        course = create(:course, start: '2016-03-20', end: '2016-03-31'.to_date.end_of_day)
        user = create(:user, username: 'Tedholtby')
        create(:courses_user, course:,
                              user:,
                              role: CoursesUsers::Roles::STUDENT_ROLE)

        described_class.import_revisions(course, all_time: true)

        expect(course.reload.revisions.count).to eq(3)
        expect(course.reload.revisions.count).to eq(3)
      end
    end

    it 'imports revisions soon after the final day of the course, but excludes them from metrics' do
      VCR.use_cassette 'course_revision_updater' do
        course = create(:course, start: '2016-03-20', end: '2016-03-30')
        user = create(:user, id: 15, username: 'Tedholtby')
        create(:courses_user, course:, user:,
                              role: CoursesUsers::Roles::STUDENT_ROLE)

        described_class.import_revisions(course, all_time: false)

        expect(user.reload.revisions.count).to eq(3)
        expect(course.reload.revisions.count).to eq(0)
      end
    end

    it 'handles returning users with earlier revisions' do
      VCR.use_cassette 'revisions/returning_students' do
        # Create a user who has a revision from long ago
        create(:trained, id: 5) # This is user Ragesoss, with edits since 2015.
        create(:revision,
               user_id: 5,
               article_id: 1,
               date: '2013-01-01'.to_date)
        # Also a revision from during the course.
        create(:revision,
               user_id: 5,
               article_id: 2,
               date: '2015-02-01'.to_date)
        create(:article, id: 1)
        create(:article, id: 2)
        # Create a recent course and add the user to it.
        create(:course,
               id: 1,
               start: '2015-01-01'.to_date,
               end: '2030-01-01'.to_date)
        create(:courses_user,
               course_id: 1,
               user_id: 5,
               role: 0)
        CoursesUsers.update_all_caches(CoursesUsers.all)
        described_class.import_revisions(Course.find(1), all_time: true)
        expect(Revision.all.count > 1).to be true
      end
    end

    it 'skips import for ArticleScopedCourse with no tracked articles' do
      expect_any_instance_of(RevisionImporter).not_to receive(:import_revisions_for_course)
      course = create(:article_scoped_program)
      student = create(:user)
      create(:courses_user, course:, user: student)
      described_class.import_revisions(course, all_time: true)
    end
  end
end
