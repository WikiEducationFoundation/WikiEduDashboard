require 'rails_helper'
require "#{Rails.root}/lib/importers/course_importer"
require "#{Rails.root}/lib/importers/revision_importer"

describe Revision do
  describe '#update' do
    it 'should update a revision with new data' do
      revision = build(:revision,
                       id: 1,
                       article_id: 1,
                       views: 1000
      )
      revision.update(
        user_id: 1,
        views: 9000
      )
      expect(revision.views).to eq(9000)
      expect(revision.user_id).to eq(1)
    end
  end

  describe '.update_all_revisions' do
    it 'should fetch revisions for existing courses' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        # Try it with no courses.
        RevisionImporter.update_all_revisions
        expect(Revision.all.count).to eq(0)

        # Now add a course with users
        VCR.use_cassette 'wiki/course_data' do
          CourseImporter.update_all_courses(false, hash: '351')
        end

        RevisionImporter.update_all_revisions nil, true
        # When the non-students are included, Revisions count is 1919.
        expect(Revision.all.count).to eq(433)
        # When the non-students are included, ArticlesCourses count is 224.
        expect(ArticlesCourses.all.count).to eq(10)

        # Update the revision counts, then try update_all_revisions again
        # to test how it handles old users.
        User.update_all_caches(Course.find(351).users)
        RevisionImporter.update_all_revisions nil, true
        expect(Revision.all.count).to eq(433)
        expect(ArticlesCourses.all.count).to eq(10)
      end
    end
  end
end
