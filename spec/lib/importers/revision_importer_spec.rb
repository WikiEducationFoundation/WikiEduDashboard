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

  describe '.move_or_delete_revisions' do
    it 'should update the article_id for a moved revision' do
      # https://en.wikipedia.org/w/index.php?title=Selfie&oldid=547645475
      create(:revision,
             id: 547645475,
             article_id: 1) # Not the actual article_id
      revision = Revision.all
      RevisionImporter.move_or_delete_revisions(revision)
      article_id = Revision.find(547645475).article_id
      expect(article_id).to eq(38956275)
      expect(Article.exists?(38956275)).to be true
    end
  end
end
