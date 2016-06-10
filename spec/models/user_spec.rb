# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  username            :string(255)
#  created_at          :datetime
#  updated_at          :datetime
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
#  greeted             :boolean          default(FALSE)
#  greeter             :boolean          default(FALSE)
#

require 'rails_helper'

describe User do
  describe 'user creation' do
    it 'creates User objects' do
      ragesock = build(:user)
      ragesauce = build(:admin)
      expect(ragesock.username).to eq('Ragesock')
      expect(ragesauce.admin?).to be true
    end
  end

  describe '#role' do
    it 'grants instructor permission for a user creating a new course' do
      course = nil
      user = create(:user)
      role = user.role(course)
      expect(role).to eq(1)
    end

    it 'treats an admin like the instructor' do
      course = create(:course)
      admin = create(:admin)
      role = admin.role(course)
      expect(role).to eq(1)
    end

    it 'returns the assigned role for a non-admin' do
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

    it 'returns -1 for a user who is not part of the course' do
      course = create(:course)
      user = create(:user)
      role = user.role(course)
      expect(role).to eq(-1)
    end
  end

  describe '#can_edit?' do
    it 'returns true for users with non-student roles' do
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

    it 'returns false for students and visitors' do
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

  describe 'email validation' do
    context 'when email is valid' do
      it 'saves the email' do
        user = User.new(username: 'foo', email: 'me@foo.com')
        user.save
        expect(user.email).to eq('me@foo.com')
      end
    end

    context 'when email is not valid' do
      it 'sets email to nil and saves' do
        user = User.new(username: 'foo', email: 'me@foo')
        user.save
        expect(user.email).to be_nil
      end
    end
  end
end
