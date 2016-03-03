# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  username            :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  character_sum       :integer          default(0)
#  view_sum            :integer          default(0)
#  course_count        :integer          default(0)
#  article_count       :integer          default(0)
#  revision_count      :integer          default(0)
#  trained             :boolean          default(FALSE)
#  global_id           :integer
#  remember_created_at :datetime
#  remember_token      :string(255)
#  wiki_token          :string(255)
#  wiki_secret         :string(255)
#  permissions         :integer          default(0)
#  real_name           :string(255)
#  email               :string(255)
#  onboarded           :boolean          default(FALSE)
#

require 'rails_helper'

describe User do
  describe 'user creation' do
    it 'should create User objects' do
      ragesock = build(:user)
      ragesoss = build(:trained)
      ragesauce = build(:admin)
      expect(ragesock.username).to eq('Ragesock')
      # rubocop:disable Metrics/LineLength
      expect(ragesoss.contribution_url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Special:Contributions/Ragesoss")
      # rubocop:enable Metrics/LineLength
      expect(ragesauce.admin?).to be true
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
      expect(user.student?(course)).to eq(true)
      expect(user.instructor?(course)).to eq(false)

      # Now let's make this user also an instructor.
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 1) # instructor
      expect(user.instructor?(course)).to eq(true)

      # User is only an instructor, not an admin.
      adminship = user.roles(course)[:admin]
      expect(adminship).to eq(false)
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

    it 'should return false for students and visitors' do
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
