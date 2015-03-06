require 'rails_helper'

describe Revision do

  describe '#update' do
    it 'should update a revision with new data' do
      revision = build(:revision,
        id: 1,
        article_id: 1,
      )
      revision.update({
        user_id: 1,
        views: 9000
      })
      expect(revision.views).to eq(9000)
      expect(revision.user_id).to eq(1)
    end
  end

  describe '.update_all_revisions' do
    it 'should fetch revisions for all courses' do
      VCR.use_cassette 'revisions/update_all_revisions' do
        # Try it with no courses.
        Revision.update_all_revisions

        # Now add a course with a user.
        build(:course,
          id: 1,
          start: '2014-01-01'.to_date,
          end: '2015-01-01'.to_date,
        ).save
        build(:user,
          id: 1,
          wiki_id: 'Ragesoss',
        ).save
        build(:courses_user,
          id: 1,
          user_id: 1,
          course_id: 1,
        ).save

        # Try it again with data to pull.
        #FIXME: This one will fail.
        #Revision.update_all_revisions
      end
    end
  end
  
end
