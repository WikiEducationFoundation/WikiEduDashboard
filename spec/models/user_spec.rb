require 'rails_helper'

describe User do
  describe 'user creation' do
    it 'should create User objects' do
      ragesock = build(:user)
      ragesoss = build(:trained)
      ragesauce = build(:admin)
      expect(ragesock.wiki_id).to eq('Ragesock')
      # rubocop:disable Metrics/LineLength
      expect(ragesoss.contribution_url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Special:Contributions/Ragesoss")
      # rubocop:enable Metrics/LineLength
      expect(ragesauce.admin?).to be true
    end

    it 'should cache User activity' do
      build(:user,
            id: 1,
            wiki_id: 'Ragesoss').save

      build(:course,
            id: 1,
            start: '2015-01-01'.to_date,
            end: '2015-07-01'.to_date,
            title: 'Underwater basket-weaving').save

      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0,
            views: 1234).save

      build(:revision,
            id: 1,
            user_id: 1,
            article_id: 1,
            date: '2015-01-01'.to_date,
            characters: 9000,
            views: 1234).save

      build(:revision,
            id: 2,
            user_id: 1,
            article_id: 1,
            date: '2015-03-01'.to_date,
            characters: 3000,
            views: 567).save

      # Assign the article to the user.
      build(:assignment,
            course_id: 1,
            user_id: 1,
            article_id: 1,
            article_title: 'Selfie').save

      # Make a course-user and save it.
      build(:courses_user,
            id: 1,
            course_id: 1,
            user_id: 1,
            assigned_article_title: 'Selfie').save

      # Make an article-course.
      build(:articles_course,
            id: 1,
            article_id: 1,
            course_id: 1).save

      Article.update_all_caches
      User.update_all_caches

      user = User.all.first
      expect(user.view_sum).to eq(1234)
      expect(user.course_count).to eq(1)
      expect(user.revision_count).to eq(2)
      expect(user.revision_count('2015-02-01'.to_date)).to eq(1)
      expect(user.article_count).to eq(1)
    end
  end

  describe '#role' do
    it 'should grant instructor permission for a user creating a new course' do
      course = nil
      user = create(:user)
      role = user.role(course)
      expect(role).to eq(1)
    end

    it 'should treat an admin like the instructor' do
      course = create(:course)
      admin = create(:admin)
      role = admin.role(course)
      expect(role).to eq(1)
    end

    it 'should return the assigned role for a non-admin' do
      course = create(:course,
                      id: 1)
      user = create(:user,
                    id: 1)
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 0) # student
      role = user.role(course)
      expect(role).to eq(0)

      # Now let's make this user also an instructor.
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 1) # instructor
      # role = user.role(course)
      # FIXME: User#role does not account for users with multiple roles.
      # We can probably disable the option of multiple roles when we disconnect
      # the MediaWiki EP extension. For the sake of permissions, though, #role
      # probably ought to return the most permissive role for a user.
      # expect(role).to eq(1)
    end

    it 'should return -1 for a user who is not part of the course' do
      course = create(:course)
      user = create(:user)
      role = user.role(course)
      expect(role).to eq(-1)
    end
  end

  describe '#can_edit?' do
    it 'should return true for users with non-student roles' do
      course = create(:course,
                      id: 1)
      user = create(:user,
                    id: 1)
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 1) # instructor
      permission = user.can_edit?(course)
      expect(permission).to be true
    end

    it  'should return false for students and visitors' do
      course = create(:course,
                      id: 1)
      user = create(:user,
                    id: 1)
      # User is not associated with course.
      permission = user.can_edit?(course)
      expect(permission).to be false

      # Now user is a student.
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 0) # instructor
      permission = user.can_edit?(course)
      expect(permission).to be false
    end
  end
end
