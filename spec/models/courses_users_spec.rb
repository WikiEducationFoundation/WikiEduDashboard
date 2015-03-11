require 'rails_helper'

describe CoursesUsers, type: :model do
  describe '.update_all_caches' do
    it 'should update data for course-user relationships' do
      # Add a user, a course, an article, and a revision.
      build(:user,
            id: 1,
            wiki_id: 'Ragesoss'
      ).save

      build(:course,
            id: 1,
            start: '2015-01-01'.to_date,
            end: '2015-07-01'.to_date,
            title: 'Underwater basket-weaving'
      ).save

      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0
      ).save

      build(:revision,
            id: 1,
            user_id: 1,
            article_id: 1,
            date: '2015-03-01'.to_date,
            characters: 9000
      ).save

      # Assign the article to the user.
      build(:assignment,
            course_id: 1,
            user_id: 1,
            article_id: 1,
            article_title: 'Selfie'
      ).save

      # Make a course-user and save it.
      build(:courses_user,
                          id: 1,
                          course_id: 1,
                          user_id: 1,
                          assigned_article_title: 'Selfie'
      ).save

      # Make an article-course.
      build(:articles_course,
            id: 1,
            article_id: 1,
            course_id: 1
      ).save

      # Update caches for all CoursesUsers
      CoursesUsers.update_all_caches

      # Fetch the created CoursesUsers entry
      course_user = CoursesUsers.all.first

      # Check to see if the expected data got cached
      expect(course_user.revision_count).to eq(1)
      expect(course_user.assigned_article_title).to eq('Selfie')
      expect(course_user.character_sum_ms).to eq(9000)
      expect(course_user.character_sum_us).to eq(0)
    end
  end
end
