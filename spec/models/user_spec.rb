# frozen_string_literal: true

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
#  locale              :string(255)
#  chat_password       :string(255)
#  chat_id             :string(255)
#  registered_at       :datetime
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

  describe 'user deletion' do
    it 'destroys the User and associated CampaignsUsers and CoursesUsers' do
      user = create(:user)
      course = create(:course)
      create(:courses_user, user_id: user.id, course_id: course.id)
      create(:campaigns_user, user_id: user.id)
      expect(CoursesUsers.count).to eq(1)
      expect(CampaignsUsers.count).to eq(1)
      user.destroy
      expect(CoursesUsers.count).to eq(0)
      expect(CampaignsUsers.count).to eq(0)
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
      expect(user.course_student?).to eq(true)
      expect(user.instructor?(course)).to eq(false)

      # Now let's make this user also an instructor.
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 1) # instructor
      expect(user.instructor?(course)).to eq(true)
      expect(user.course_instructor?).to eq(true)

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

  describe '#returning_instructor?' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:subject) { user.returning_instructor? }
    let(:add_user_as_instructor) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    let(:add_user_as_student) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:approve_course) do
      create(:campaigns_course, campaign_id: Campaign.first.id, course_id: course.id)
    end

    context 'when user has no courses' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when user has just created their first course' do
      before do
        add_user_as_instructor
      end
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when user is a student in an approved course' do
      before do
        approve_course
        add_user_as_student
      end
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
    context 'when user is an instructor in an approved course' do
      before do
        approve_course
        add_user_as_instructor
      end
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe '#search' do
    let(:search_user) { create(:user, email: 'findme@example.com', real_name: 'Find Me') }
    let(:similar_search_user) { create(:user, username: 'similar', email: 'find@example.com') }

    it 'returns user(s) with given email address' do
      result = User.search_by_email(search_user.email)

      expect(result).to eq([search_user])
    end

    it 'returns user(s) with given full name' do
      result = User.search_by_real_name(search_user.real_name)
      expect(result).to eq([search_user])
    end

    it 'returns user(s) without full email' do
      # The word 'find' is present in both emails.
      result = User.search_by_email('find')

      expect(result).to eq([search_user, similar_search_user])
    end
  end
end
