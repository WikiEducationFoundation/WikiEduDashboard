require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/cleaners"

describe RevisionImporter do
  describe '.update_all_revisions' do
    it 'should fetch revisions for existing courses' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        # Try it with no courses.
        RevisionImporter.update_all_revisions
        expect(Revision.all.count).to eq(0)

        # Now add a course with users
        VCR.use_cassette 'wiki/course_data' do
          CourseImporter.update_all_courses(false, cohort: [351])
        end

        RevisionImporter.update_all_revisions nil, true
        # When the non-students are included, Revisions count is 1919.
        expect(Revision.all.count).to eq(519)
        # When the non-students are included, ArticlesCourses count is 224.
        expect(ArticlesCourses.all.count).to eq(10)

        # Update the revision counts, then try update_all_revisions again
        # to test how it handles old users.
        User.update_all_caches(Course.find(351).users)
        RevisionImporter.update_all_revisions nil, true
        expect(Revision.all.count).to eq(519)
        expect(ArticlesCourses.all.count).to eq(10)
      end
    end

    it 'should not fail with returning students' do
      VCR.use_cassette 'revisions/returning_students' do
        # Create a user who has a revision from long ago
        create(:trained) # This is user 319203, with edits since 2015.
        create(:revision,
               user_id: 319203,
               date: '2003-03-01'.to_date)
        # Create a recent course and add the user to it.
        create(:course,
               id: 1,
               start: '2015-01-01'.to_date,
               end: '2030-01-01'.to_date)
        create(:courses_user,
               course_id: 1,
               user_id: 319203,
               role: 0)
        User.update_all_caches(Course.find(1).users)
        RevisionImporter.update_all_revisions nil, true
        expect(Revision.all.count > 1).to be true
      end
    end
  end

  describe '.update_assignment_article_ids' do
    it 'should add article ids to assignments after importing revisions' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        VCR.use_cassette 'wiki/course_data' do
          CourseImporter.update_all_courses(false, cohort: [351])
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

    it 'should only update article_ids for mainspace titles' do
      create(:assignment,
             id: 1,
             article_title: 'Foo',
             article_id: nil)
      create(:assignment,
             id: 2,
             article_title: 'Bar',
             article_id: nil)
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

  describe '.repair_orphan_revisions' do
    it 'should import articles for orphaned revisions' do
      # We start with revision and article
      create(:revision,
             id: 661324615,
             article_id: 46640378,
             user_id: 24593901,
             date: '2015-05-07 23:22:33')
      create(:article,
             id: 46640378,
             namespace: 0)
      create(:user,
             id: 24593901,
             wiki_id: 'Rothscak')
      create(:courses_user,
             course_id: 1,
             user_id: 24593901)
      create(:course,
             id: 1,
             start: '2015-01-01',
             end: '2016-01-01')
      ArticlesCourses.update_from_revisions
      # Now the id of the articles changes via
      # ArticleImporter.update_article_status, but the process duplicates
      # before the orphaned revisions get processed in the normal way.
      article = Article.find(46640378)
      article.id = 2
      article.save

      # Now ArticlesCourses.update_all_caches will break until the revisions
      # are de-orphaned (issue #93). So let's try to de-orphan them.
      Cleaners.repair_orphan_revisions
      ArticlesCourses.update_from_revisions
      ArticlesCourses.update_all_caches
    end
  end
end
