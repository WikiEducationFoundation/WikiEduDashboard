require 'rails_helper'

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
        Revision.update_all_revisions
        expect(Revision.all.count).to eq(0)

        # Now add a course with users
        VCR.use_cassette 'wiki/course_data' do
          Course.update_all_courses(false, hash: '351')
        end
        Revision.update_all_revisions
        expect(Revision.all.count).to eq(433)
      end
    end
  end
end
