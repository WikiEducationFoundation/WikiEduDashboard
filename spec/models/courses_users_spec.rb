require 'rails_helper'

describe CoursesUsers, type: :model do
  describe '.update_all_caches' do
    it 'should update data for course-user relationships' do
      # Add a user, a course, an article, and a revision.
      create(:user,
             id: 1,
             wiki_id: 'Ragesoss')

      create(:course,
             id: 1,
             start: '2015-01-01'.to_date,
             end: '2015-07-01'.to_date,
             title: 'Underwater basket-weaving')

      create(:article,
             id: 1,
             title: 'Selfie',
             namespace: 0)

      create(:revision,
             id: 1,
             user_id: 1,
             article_id: 1,
             date: '2015-03-01'.to_date,
             characters: 9000)

      # Assign the article to the user.
      create(:assignment,
             course_id: 1,
             user_id: 1,
             article_id: 1,
             article_title: 'Selfie')

      # Make a course-user and save it.
      create(:courses_user,
             id: 1,
             course_id: 1,
             user_id: 1,
             assigned_article_title: 'Selfie')

      # Make an article-course.
      create(:articles_course,
             id: 1,
             article_id: 1,
             course_id: 1)

      # Update caches for all CoursesUsers
      CoursesUsers.update_all_caches(CoursesUsers.where(id: 1).first)

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
