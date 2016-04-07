require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"
require "#{Rails.root}/lib/cleaners"

describe RevisionImporter do
  describe '.update_all_revisions' do
    it 'fetches revisions for existing courses' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        # Try it with no courses.
        RevisionImporter.update_all_revisions
        expect(Revision.all.count).to eq(0)

        # Now add a course with users
        VCR.use_cassette 'wiki/course_data' do
          LegacyCourseImporter.update_all_courses(false, cohort: [351])
        end

        RevisionImporter.update_all_revisions nil, true
        # When the non-students are included, Revisions count is 1919.
        expect(Revision.all.count).to eq(519)
        # When the non-students are included, ArticlesCourses count is 224.
        expect(ArticlesCourses.all.count).to eq(10)

        # Update the revision counts, then try update_all_revisions again
        # to test how it handles old users.
        RevisionImporter.update_all_revisions nil, true
        expect(Revision.all.count).to eq(519)
        expect(ArticlesCourses.all.count).to eq(10)
      end
    end

    it 'includes revisions on the final day of a course' do
      create(:course, id: 1, start: '2016-03-20', end: '2016-03-31')
      create(:user, id: 27860490, username: 'Tedholtby')
      create(:courses_user, course_id: 1,
                            user_id: 27860490,
                            role: CoursesUsers::Roles::STUDENT_ROLE)

      RevisionImporter.update_all_revisions nil, true

      expect(User.find(27860490).revisions.count).to eq(3)
      expect(Course.find(1).revisions.count).to eq(3)

      expected_user_id = User.find_by(username: 'Tedholtby').id
      expected_article_id = Article.find_by(wiki_id: 1,
                                            title: '1978_Revelation_on_Priesthood',
                                            mw_page_id: 15124285).id
      expected_rev = Revision.find_by(mw_rev_id: 712907095,
                                      user_id: expected_user_id,
                                      wiki_id: 1,
                                      mw_page_id: 15124285,
                                      characters: 579,
                                      article_id: expected_article_id)
      expect(expected_rev).to be_a(Revision)
    end

    it 'excludes revisions after the final day of the course' do
      create(:course, id: 1, start: '2016-03-20', end: '2016-03-30')
      create(:user, id: 27860490, username: 'Tedholtby')
      create(:courses_user, course_id: 1, user_id: 27860490, role: CoursesUsers::Roles::STUDENT_ROLE)

      RevisionImporter.update_all_revisions nil, true

      expect(User.find(27860490).revisions.count).to eq(0)
    end

    it 'handles returning users with earlier revisions' do
      VCR.use_cassette 'revisions/returning_students' do
        # Create a user who has a revision from long ago
        create(:trained) # This is user 319203, with edits since 2015.
        create(:revision,
               user_id: 319203,
               article_id: 1,
               date: '2013-01-01'.to_date)
        # Also a revision from during the course.
        create(:revision,
               user_id: 319203,
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
               user_id: 319203,
               role: 0)
        CoursesUsers.update_all_caches
        RevisionImporter.update_all_revisions nil, true
        expect(Revision.all.count > 1).to be true
      end
    end
  end

  describe '.users_with_no_revisions' do
    let(:subject)   { RevisionImporter.new }
    let(:user)      { create(:user) }
    let(:course_1)  { create(:course, start: '2015-01-01', end: '2015-12-31') }
    let(:course_2)  { create(:course, start: '2016-01-01', end: '2016-12-31') }

    let!(:cu)       { create(:courses_user, course_id: course_1.id, user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE) }
    let!(:cu2)      { create(:courses_user, course_id: course_2.id, user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE) }

    let(:article)   { create(:article) }
    let!(:revision) { create(:revision, user_id: user.id, article_id: article.id, date: course_1.start + 1.month) }

    before { CoursesUsers.all.collect(&:update_cache) }

    it 'returns users who have no revisions for the given course' do
      expect(subject.send(:users_with_no_revisions, course_2)).to include(user)
    end

    it 'does not return users who have revisions for the course' do
      expect(subject.send(:users_with_no_revisions, course_1)).not_to include(user)
    end
  end

  describe '.update_assignment_article_ids' do
    it 'adds article ids to assignments after importing revisions' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        VCR.use_cassette 'wiki/course_data' do
          LegacyCourseImporter.update_all_courses(false, cohort: [351])
        end
        # .update_all_revisions calls .update_assignment_article_ids at the end.
        RevisionImporter.update_all_revisions nil, true
        # Only assignments that had revisions by course participants should have
        # an article_id.
        expect(Assignment.all.count).to eq(27)
        expect(Assignment.where(role: 0).count).to eq(11)
        expect(Assignment.where.not(article_id: nil).count).to eq(26)
      end
    end

    it 'only updates article_ids for mainspace titles' do
      create(:course, id: 1)
      create(:assignment,
             id: 1,
             article_title: 'Foo',
             article_id: nil,
             course_id: 1)
      create(:assignment,
             id: 2,
             article_title: 'Bar',
             article_id: nil,
             course_id: 1)
      create(:article,
             id: 123,
             title: 'Foo',
             namespace: 0)
      create(:article,
             id: 456,
             title: 'Bar',
             namespace: 2)
      expect(Assignment.where.not(article_id: nil).count).to eq(0)
      AssignmentImporter.update_assignment_article_ids
      expect(Assignment.where.not(article_id: nil).count).to eq(1)
    end
  end

  describe '.move_or_delete_revisions' do
    it 'updates the article_id for a moved revision' do
      # https://en.wikipedia.org/w/index.php?title=Selfie&oldid=547645475
      create(:revision,
             id: 547645475,
             article_id: 1) # Not the actual article_id
      revision = Revision.all
      RevisionImporter.new.move_or_delete_revisions(revision)
      article_id = Revision.find(547645475).article_id
      expect(article_id).to eq(38956275)
      expect(Article.exists?(38956275)).to be true
    end
  end
end
